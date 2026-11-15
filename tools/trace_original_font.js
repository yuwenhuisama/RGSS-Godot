// Frida probe for the isolated original fixture; records calls without changing them.
const gdi = Process.getModuleByName('gdi32.dll');
let compressionInstructionsRecorded = false;
for (const encoding of ['A', 'W']) {
  Interceptor.attach(gdi.getExportByName('CreateFont' + encoding), {
    onEnter(args) {
      const name = args[13].isNull() ? '' : encoding === 'W' ? args[13].readUtf16String() : args[13].readAnsiString();
      console.log('ORIGINAL_CREATE_FONT:' + JSON.stringify({encoding, height: args[0].toInt32(), width: args[1].toInt32(), name}));
    }
  });
  Interceptor.attach(gdi.getExportByName('CreateFontIndirect' + encoding), {
    onEnter(args) {
      const data = args[0];
      const name = encoding === 'W' ? data.add(28).readUtf16String() : data.add(28).readAnsiString();
      console.log('ORIGINAL_CREATE_FONT_INDIRECT:' + JSON.stringify({encoding, height: data.readS32(), width: data.add(4).readS32(), name, caller: this.returnAddress.toString()}));
      if (data.add(4).readS32() > 0 && name === 'nsimsun') {
        console.log('ORIGINAL_FONT_STACK:' + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join(' | '));
        if (!compressionInstructionsRecorded) {
          compressionInstructionsRecorded = true;
          const rgss = Process.getModuleByName('RGSS300.dll');
          Interceptor.attach(rgss.base.add(0x19860), {
            onEnter() {
              const frame = this.context.ebp;
              const font = frame.sub(0x44).readPointer();
              console.log('ORIGINAL_COMPRESSION_PARAMETERS:' + JSON.stringify({height: font.add(0x48).readS32(), scale: font.add(0xa8).readDouble(), referenceAverage: frame.sub(0x2c).readS32(), referenceHeight: frame.sub(0x40).readS32()}));
            }
          });
          let scaleAddress = rgss.base.add(0x7200);
          console.log('ORIGINAL_SCALE_CONSTANTS:' + JSON.stringify({subtract: rgss.base.add(0x1a79c0).readDouble(), minimum: rgss.base.add(0x1a79b8).readDouble()}));
          for (let index = 0; index < 110; index++) {
            const instruction = Instruction.parse(scaleAddress);
            console.log('ORIGINAL_SCALE_INSTRUCTION:' + instruction.address.sub(rgss.base) + ':' + instruction.toString());
            scaleAddress = instruction.next;
          }
          let address = rgss.base.add(0x197a0);
          for (let index = 0; index < 160; index++) {
            const instruction = Instruction.parse(address);
            console.log('ORIGINAL_LIVE_INSTRUCTION:' + instruction.address.sub(rgss.base) + ':' + instruction.toString());
            address = instruction.next;
          }
        }
      }
    }
  });
}
console.log('ORIGINAL_FONT_TRACE_READY');
Process.attachModuleObserver({
  onAdded(rgss) {
    if (rgss.name.toLowerCase() !== 'rgss300.dll') return;
    console.log('ORIGINAL_RGSS_BASE:' + rgss.base);
    let instructionAddress = rgss.base.add(0x1f120);
    for (let index = 0; index < 55; index++) {
      const instruction = Instruction.parse(instructionAddress);
      console.log('ORIGINAL_COMPRESSION_INSTRUCTION:' + instruction.address.sub(rgss.base) + ':' + instruction.toString());
      instructionAddress = instruction.next;
    }
  }
});
for (const name of ['GetTextMetricsA', 'GetTextMetricsW']) {
  Interceptor.attach(gdi.getExportByName(name), {
    onEnter(args) { this.metrics = args[1]; this.dc = args[0].toString(); this.caller = this.returnAddress.toString(); },
    onLeave(result) {
      if (result.toInt32()) console.log('ORIGINAL_FONT_METRICS:' + JSON.stringify({name, dc: this.dc, caller: this.caller, height: this.metrics.readS32(), average: this.metrics.add(20).readS32(), maximum: this.metrics.add(24).readS32()}));
    }
  });
}
Interceptor.attach(gdi.getExportByName('GetObjectW'), {
  onEnter(args) { this.buffer = args[2]; this.size = args[1].toInt32(); },
  onLeave(result) {
    if (result.toInt32() === 92 && this.size >= 92) console.log('ORIGINAL_LOGFONT:' + JSON.stringify({height: this.buffer.readS32(), width: this.buffer.add(4).readS32(), name: this.buffer.add(28).readUtf16String()}));
  }
});
Interceptor.attach(gdi.getExportByName('GetTextExtentPoint32W'), {
  onEnter(args) { this.text = args[1].readUtf16String(args[2].toInt32()); this.size = args[3]; },
  onLeave(result) {
    if (result.toInt32()) console.log('ORIGINAL_EXTENT:' + JSON.stringify({text: this.text, width: this.size.readS32(), height: this.size.add(4).readS32()}));
  }
});
Interceptor.attach(gdi.getExportByName('GetObjectA'), {
  onEnter(args) { this.buffer = args[2]; this.size = args[1].toInt32(); },
  onLeave(result) {
    if (result.toInt32() === 60 && this.size >= 60) console.log('ORIGINAL_LOGFONT_A:' + JSON.stringify({height: this.buffer.readS32(), width: this.buffer.add(4).readS32(), name: this.buffer.add(28).readAnsiString()}));
  }
});
