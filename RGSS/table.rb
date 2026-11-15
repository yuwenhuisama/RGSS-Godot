# encoding: utf-8
require 'type_check_util'

class Table
  include TypeCheckUtil

  attr_reader :__handler__

  def initialize(xsize, *dimensions)
    raise ArgumentError, 'Invalid number of arguments' if dimensions.size > 2
    @dimension = 1 + dimensions.size
    ysize, zsize = dimensions
    ysize = 1 if dimensions.size < 1
    zsize = 1 if dimensions.size < 2
    check_arguments([xsize, ysize, zsize], [Integer, Integer, Integer])
    @__handler__ = Unity::Table.new_xyz(xsize, ysize, zsize)
  end

  def resize(xsize, *dimensions)
    raise ArgumentError, 'Invalid number of arguments' if dimensions.size > 2
    @dimension = 1 + dimensions.size
    ysize, zsize = dimensions
    ysize = 1 if dimensions.size < 1
    zsize = 1 if dimensions.size < 2
    check_arguments([xsize, ysize, zsize], [Integer, Integer, Integer])
    @__handler__.resize(xsize, ysize, zsize)
  end

  def [](*args)
    raise ArgumentError, "wrong number of arguments (#{@dimension} for #{args.size})" unless args.size == @dimension
    if args.size == 1
      check_arguments(args, [Integer])
      x, = args
      @__handler__.get_x(x)
    elsif args.size == 2
      check_arguments(args, [Integer, Integer])
      x, y = args
      @__handler__.get_xy(x, y)
    elsif args.size == 3
      check_arguments(args, [Integer, Integer, Integer])
      x, y, z = args
      @__handler__.get_xyz(x, y, z)
    else
      raise ArgumentError.new("Invalid number of arguments")
    end
  end

  def []=(*args)
    raise ArgumentError, "wrong number of arguments (#{@dimension} for #{args.size - 1})" unless args.size == @dimension + 1
    if args.size == 2
      check_arguments(args, [Integer, Integer])
      x, val = args
      @__handler__.set_x(x, val)
    elsif args.size == 3
      check_arguments(args, [Integer, Integer, Integer])
      x, y, val = args
      @__handler__.set_xy(x, y, val)
    elsif args.size == 4
      check_arguments(args, [Integer, Integer, Integer, Integer])
      x, y, z, val = args
      @__handler__.set_xyz(x, y, z, val)
    else
      raise ArgumentError.new("Invalid number of arguments")
    end
  end
  
  def eql?(other)
    if self == other
      true
    end
    self.__handler__ == other.__handler__
  end

  def hash
    @__handler__.hash
  end

  # refer from https://forum.chaos-project.com/index.php?topic=9103.0
  def _dump(d = 0)
    s = [@dimension].pack('L')
    s += [self.xsize].pack('L') + [self.ysize].pack('L') + [self.zsize].pack('L')
    s += [self.xsize * self.ysize * self.zsize].pack('L')
    for z in 0...self.zsize
      for y in 0...self.ysize
        for x in 0...self.xsize
          s += [@__handler__.get_xyz(x, y, z)].pack('S')
        end
      end
    end
    s
  end

  def self._load(s)
    size = s[0, 4].unpack('L')[0]
    nx = s[4, 4].unpack('L')[0]
    ny = s[8, 4].unpack('L')[0]
    nz = s[12, 4].unpack('L')[0]
    data = []
    pointer = 20
    loop do
      data.push(*s[pointer, 2].unpack('S'))
      pointer += 2
      break if pointer > s.size - 1
    end
    t = Table.new(*[nx, ny, nz][0, size])
    n = 0
    for z in 0...nz
      for y in 0...ny
        for x in 0...nx
          t.__handler__.set_xyz(x, y, z, data[n])
          n += 1
        end
      end
    end
    t
  end

  [:xsize, :ysize, :zsize].each do |prop|
    define_method(prop) { @__handler__.send(prop) }
  end

end
