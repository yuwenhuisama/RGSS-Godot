// Read-only tracing of the isolated original fixture's draw vertices and matrices.
let deviceHooked = false;
{
  const module = Process.getModuleByName('RGSS300.dll');
  let waveCalls = 0;
  let waveRows = 0;
  Interceptor.attach(module.base.add(0x1eb69), {
    onEnter() {
      if (waveRows++ >= 6) return;
      const frame = this.context.ebp;
      console.log('ORIGINAL_WAVE_RECTS:' + JSON.stringify({
        bounds: [0x9c,0x98,0x94,0x90].map(offset => frame.sub(offset).readS32()),
        source: [0x54,0x50,0x4c,0x48].map(offset => frame.sub(offset).readS32()),
        width: frame.sub(0xa8).readS32(), y: frame.sub(0xbc).readS32()
      }));
    }
  });
  Interceptor.attach(module.base.add(0x1ee70), {
    onEnter(args) {
      this.recordWave = waveCalls++ < 120;
      if (!this.recordWave) return;
      const object = this.context.ecx;
      this.waveInput = {phase: args[0].toInt32(), x: object.add(0xdc).readS32(), angle: object.add(0x100).readDouble(), lengthField: object.add(0x10c).readS32(), phaseField: object.add(0x118).readDouble()};
    },
    onLeave(result) {
      if (this.recordWave) console.log('ORIGINAL_WAVE_LOOKUP:' + JSON.stringify({...this.waveInput, result: result.toInt32()}));
    }
  });
  let internalCalls = 0;
  let sampledRows = 0;
  Interceptor.attach(module.base.add(0x1e44c), {
    onEnter() {
      const frame = this.context.ebp;
      const object = frame.sub(0xac).readPointer();
      if (object.add(0x108).readS32() == 0 || sampledRows++ >= 18) return;
      console.log('ORIGINAL_SAMPLE_ROW:' + JSON.stringify({
        angle: object.add(0x100).readDouble(),
        left: frame.sub(0x5c).readS32(), y: frame.sub(0x74).readS32(), width: frame.sub(0x64).readS32(),
        u: frame.sub(0x84).readDouble(), v: frame.sub(0x7c).readDouble(),
        sin: frame.sub(0x3c).readDouble(), cos: frame.sub(0x14).readDouble()
      }));
    }
  });
  Interceptor.attach(module.base.add(0x180fe0), {
    onEnter() {
      if (internalCalls++ >= 12) return;
      console.log('ORIGINAL_INTERNAL_TRIG:' + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join(' | '));
    }
  });
  console.log('ORIGINAL_ANGLE_VALUES:' + [0x1a8ba8,0x1a8bb0,0x1a8bb8].map(offset => module.base.add(offset).readDouble()).join(','));
  let code = module.base.add(0x1ee70);
  for (let i = 0; i < 160; i++) {
    const instruction = Instruction.parse(code);
    console.log('ORIGINAL_ROTATION_INSTRUCTION:' + code.sub(module.base) + ':' + instruction);
    code = instruction.next;
  }
  for (const offset of [0x23d700, 0x23d800]) {
    console.log('ORIGINAL_LOOKUP_FLOATS:' + offset.toString(16) + ':' + Array.from({length: 32}, (_, i) => module.base.add(offset + i * 4).readFloat()).join(','));
  }
  for (const range of module.enumerateRanges('r-x')) {
    const data = new Uint8Array(range.base.readByteArray(range.size));
    const view = new DataView(data.buffer);
    for (let i = 0; i < data.length - 4; i++) {
      const value = view.getUint32(i, true);
      if (value < module.base.toUInt32() + 0x23c000 || value >= module.base.toUInt32() + 0x23e000) continue;
      if ([0xa1, 0x05, 0xdd, 0xd9].includes(data[i-1]) || data[i-2] === 0xd9 || data[i-2] === 0xf3) {
        console.log('ORIGINAL_LOOKUP_CODE:' + range.base.add(i).sub(module.base) + ':table:' + ptr(value).sub(module.base) + ':' + hexdump(range.base.add(i-16), {length: 48, header: false, ansi: false}));
      }
    }
  }
  for (const pattern of ['39 9d 52 a2 46 df 91 3f', '35 fa 8e 3c', '18 2d 44 54 fb 21 09 40', 'db 0f 49 40']) {
    const constants = Memory.scanSync(module.base, module.size, pattern);
    for (const constant of constants) {
      const bytes = constant.address.toUInt32();
      const addressPattern = [0, 8, 16, 24].map(shift => ((bytes >>> shift) & 255).toString(16).padStart(2, '0')).join(' ');
      const references = Memory.scanSync(module.base, module.size, addressPattern);
      console.log('ORIGINAL_ANGLE_CONSTANT:' + constant.address.sub(module.base) + ':refs:' + references.map(item => item.address.sub(module.base)).join(','));
      for (const reference of references.slice(0, 12)) console.log('ORIGINAL_ANGLE_CODE:' + reference.address.sub(module.base) + ':' + hexdump(reference.address.sub(32), {length: 96, header: false, ansi: false}));
    }
  }
  const matches = module.enumerateRanges('r-x').flatMap(range => Memory.scanSync(range.base, range.size, 'd9 fb'));
  console.log('ORIGINAL_LATE_FSINCOS:' + matches.map(item => item.address.sub(module.base).toString()).join(','));
  for (const item of matches) {
    console.log('ORIGINAL_TRIG_BYTES:' + item.address.sub(module.base) + ':' + hexdump(item.address.sub(32), {length: 80, header: false, ansi: false}));
  }
}
let trigonometryCalls = 0;
for (const name of ['sin', 'cos']) {
  Interceptor.attach(Process.getModuleByName('msvcrt.dll').getExportByName(name), {
    onEnter(args) {
      if (trigonometryCalls++ >= 24) return;
      console.log('ORIGINAL_TRIG_STACK:' + name + ':' + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join(' | '));
    }
  });
}
Interceptor.attach(Process.getModuleByName('kernel32.dll').getExportByName('GetProcAddress'), {
  onEnter(args) {
    this.symbol = args[1].compare(ptr(65536)) >= 0 ? args[1].readCString() : '';
  },
  onLeave(result) {
    if (/Direct3D|D3DX|glDraw|glMatrix/i.test(this.symbol)) {
      console.log('ORIGINAL_GRAPHICS_SYMBOL:' + this.symbol + ':' + result);
    }
  }
});
Process.attachModuleObserver({
  onAdded(module) {
    if (module.name.toLowerCase() === 'rgss300.dll') {
      console.log('ORIGINAL_RGSS_EXPORTS:' + module.enumerateExports().map(item => item.name).join(','));
      const initialize = module.findExportByName('RGSSInitialize3');
      if (initialize !== null) Interceptor.attach(initialize, {
        onLeave() {
          const matches = Memory.scanSync(module.base, module.size, 'd9 fb');
          console.log('ORIGINAL_FSINCOS_LOCATIONS:' + matches.slice(0, 30).map(item => item.address.sub(module.base).toString()).join(','));
        }
      });
    }
    if (/ddraw|rgss/i.test(module.name)) console.log('ORIGINAL_GRAPHICS_MODULE:' + module.name);
    if (module.name.toLowerCase() === 'ddraw.dll') {
      for (const name of ['DirectDrawCreate', 'DirectDrawCreateEx']) {
        Interceptor.attach(module.getExportByName(name), {
          onEnter(args) { this.output = args[1]; },
          onLeave(result) {
            if (result.toInt32() !== 0) return;
            const object = this.output.readPointer();
            console.log('ORIGINAL_DDRAW_CREATED:' + name);
            Interceptor.attach(object.readPointer().add(6 * Process.pointerSize).readPointer(), {
              onEnter(args) { this.surfaceOutput = args[2]; },
              onLeave(result) {
                if (result.toInt32() !== 0) return;
                const surface = this.surfaceOutput.readPointer();
                let locks = 0;
                Interceptor.attach(surface.readPointer().add(25 * Process.pointerSize).readPointer(), {
                  onEnter(args) {
                    if (locks++ >= 8) return;
                    console.log('ORIGINAL_SURFACE_LOCK_STACK:' + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join(' | '));
                  }
                });
              }
            });
          }
        });
      }
    }
    if (module.name.toLowerCase() !== 'd3d9.dll') return;
    Interceptor.attach(module.getExportByName('Direct3DCreate9'), {
      onLeave(object) {
        if (object.isNull()) return;
        const vtable = object.readPointer();
        Interceptor.attach(vtable.add(16 * Process.pointerSize).readPointer(), {
          onEnter(args) { this.output = args[6]; },
          onLeave(result) {
            if (result.toInt32() !== 0 || deviceHooked) return;
            deviceHooked = true;
            const device = this.output.readPointer();
            const methods = device.readPointer();
            let constants = 0;
            Interceptor.attach(methods.add(94 * Process.pointerSize).readPointer(), {
              onEnter(args) {
                if (constants++ >= 40) return;
                const count = Math.min(args[3].toInt32() * 4, 32);
                const values = [];
                for (let i = 0; i < count; i++) values.push(args[2].add(i * 4).readFloat());
                console.log('ORIGINAL_VERTEX_CONSTANTS:' + JSON.stringify({register: args[1].toInt32(), values}));
              }
            });
            let draws = 0;
            Interceptor.attach(methods.add(83 * Process.pointerSize).readPointer(), {
              onEnter(args) {
                if (draws++ >= 30) return;
                const stride = args[4].toInt32();
                const vertices = [];
                for (let n = 0; n < 4; n++) {
                  const values = [];
                  for (let i = 0; i < Math.min(stride / 4, 12); i++) values.push(args[3].add(n * stride + i * 4).readFloat());
                  vertices.push(values);
                }
                console.log('ORIGINAL_DRAW_VERTICES:' + JSON.stringify({type: args[1].toInt32(), primitives: args[2].toInt32(), stride, vertices}));
              }
            });
            console.log('ORIGINAL_SPRITE_TRACE_READY');
          }
        });
      }
    });
  }
});
