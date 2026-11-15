#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreAudio/CATapDescription.h>
#import <CoreAudio/AudioHardwareTapping.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

static FILE *recording;
static unsigned long long recordedBytes;
static unsigned long long callbackCount;

static OSStatus capture(AudioObjectID device, const AudioTimeStamp *now,
 const AudioBufferList *input, const AudioTimeStamp *inputTime,
 AudioBufferList *output, const AudioTimeStamp *outputTime, void *context) {
 callbackCount++;
 if (output) {
 for (UInt32 i = 0; i < output->mNumberBuffers; i++) {
  if (output->mBuffers[i].mData) memset(output->mBuffers[i].mData, 0, output->mBuffers[i].mDataByteSize);
 }
 }
 if (!input) return noErr;
 for (UInt32 i = 0; i < input->mNumberBuffers; i++) {
  const AudioBuffer *buffer = &input->mBuffers[i];
  if (buffer->mData && buffer->mDataByteSize) {
   recordedBytes += fwrite(buffer->mData, 1, buffer->mDataByteSize, recording);
  }
 }
 return noErr;
}

int main(int argc, char **argv) {
 @autoreleasepool {
  if (argc != 5) { fprintf(stderr, "Usage: capture pid seconds output.pcm output.log\n"); return 1; }
  if (!freopen(argv[4], "w", stdout)) return 1;
  if (!freopen(argv[4], "a", stderr)) return 1;
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
  [NSApp finishLaunching];
  pid_t pid = (pid_t)atoi(argv[1]);
  AudioObjectID process = kAudioObjectUnknown;
  AudioObjectPropertyAddress address = {kAudioHardwarePropertyTranslatePIDToProcessObject, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
  UInt32 size = sizeof(process);
  OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, sizeof(pid), &pid, &size, &process);
  if (status || process == kAudioObjectUnknown) { fprintf(stderr, "PROCESS_LOOKUP_FAIL:%d\n", status); return 2; }
  address.mSelector = kAudioProcessPropertyDevices;
  address.mScope = kAudioObjectPropertyScopeOutput;
  status = AudioObjectGetPropertyDataSize(process, &address, 0, NULL, &size);
  if (status || size == 0) { fprintf(stderr, "PROCESS_OUTPUT_FAIL:%d\n", status); return 2; }
  AudioObjectID *devices = malloc(size);
  status = AudioObjectGetPropertyData(process, &address, 0, NULL, &size, devices);
  AudioObjectID outputDevice = devices[0];
  free(devices);
  if (status) return 2;
  CFStringRef outputUID = NULL;
  address = (AudioObjectPropertyAddress){kAudioDevicePropertyDeviceUID, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
  size = sizeof(outputUID);
  status = AudioObjectGetPropertyData(outputDevice, &address, 0, NULL, &size, &outputUID);
  if (status) return 2;
  printf("PROCESS_OUTPUT_DEVICE:%s\n", [(__bridge NSString *)outputUID UTF8String]);
  CATapDescription *description = [[CATapDescription alloc] initStereoMixdownOfProcesses:@[@(process)]];
  description.name = @"RGSS test process audio";
  description.private = YES;
  description.muteBehavior = CATapUnmuted;
  AudioObjectID tap = kAudioObjectUnknown;
  status = AudioHardwareCreateProcessTap(description, &tap);
  if (status) { fprintf(stderr, "TAP_CREATE_FAIL:%d\n", status); return 3; }
  CFStringRef tapUID = NULL;
  address.mSelector = kAudioTapPropertyUID;
  size = sizeof(tapUID);
  status = AudioObjectGetPropertyData(tap, &address, 0, NULL, &size, &tapUID);
  if (status) { AudioHardwareDestroyProcessTap(tap); return 4; }
  AudioStreamBasicDescription format = {0};
  address.mSelector = kAudioTapPropertyFormat;
  size = sizeof(format);
  status = AudioObjectGetPropertyData(tap, &address, 0, NULL, &size, &format);
  if (status) { AudioHardwareDestroyProcessTap(tap); return 4; }
  printf("TAP_FORMAT:rate=%.0f:channels=%u:bits=%u:flags=%u:bytesPerFrame=%u\n", format.mSampleRate, format.mChannelsPerFrame, format.mBitsPerChannel, format.mFormatFlags, format.mBytesPerFrame);
  NSDictionary *deviceDescription = @{
   @kAudioAggregateDeviceNameKey: @"RGSS private capture",
   @kAudioAggregateDeviceUIDKey: NSUUID.UUID.UUIDString,
   @kAudioAggregateDeviceIsPrivateKey: @YES,
   @kAudioAggregateDeviceSubDeviceListKey: @[@{@kAudioSubDeviceUIDKey: (__bridge NSString *)outputUID}],
   @kAudioAggregateDeviceMainSubDeviceKey: (__bridge NSString *)outputUID,
   @kAudioAggregateDeviceTapAutoStartKey: @YES,
   @kAudioAggregateDeviceTapListKey: @[@{@kAudioSubTapUIDKey: (__bridge NSString *)tapUID, @kAudioSubTapDriftCompensationKey: @YES}]
  };
  CFRelease(outputUID);
  CFRelease(tapUID);
  AudioObjectID device = kAudioObjectUnknown;
  status = AudioHardwareCreateAggregateDevice((__bridge CFDictionaryRef)deviceDescription, &device);
  if (status) { AudioHardwareDestroyProcessTap(tap); fprintf(stderr, "AGGREGATE_FAIL:%d\n", status); return 5; }
  recording = fopen(argv[3], "wb");
  AudioDeviceIOProcID proc = NULL;
  if (!recording) { AudioHardwareDestroyAggregateDevice(device); AudioHardwareDestroyProcessTap(tap); return 6; }
  status = AudioDeviceCreateIOProcID(device, capture, NULL, &proc);
  if (!status) status = AudioDeviceStart(device, proc);
  if (!status) {
   puts("TAP_RECORDING_READY"); fflush(stdout);
   NSDate *end = [NSDate dateWithTimeIntervalSinceNow:atof(argv[2])];
   while (end.timeIntervalSinceNow > 0) {
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
   }
   printf("TAP_CALLBACKS:%llu:bytes=%llu\n", callbackCount, recordedBytes); fflush(stdout);
   AudioDeviceStop(device, proc);
  }
  puts("TAP_STOP_RETURNED"); fflush(stdout);
  if (proc) AudioDeviceDestroyIOProcID(device, proc);
  fclose(recording);
  AudioHardwareDestroyAggregateDevice(device);
  AudioHardwareDestroyProcessTap(tap);
  printf("TAP_RECORDING_END:status=%d:bytes=%llu\n", status, recordedBytes);
  return status || !recordedBytes ? 7 : 0;
 }
}
