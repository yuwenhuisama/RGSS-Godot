# encoding: utf-8
require 'type_check_util'

class Tilemap
  include TypeCheckUtil

  attr_reader :__handler__

  def initialize(viewport = nil)
    @__handler__ = Unity::Tilemap.new(viewport&.__handler__)
    # Persistent proxy so `tilemap.bitmaps[i] = bmp` forwards to the native handler
    # (a plain array getter would discard the assignment).
    @bitmaps = TilemapBitmapsProxy.new(@__handler__)
    @map_data = nil
    @flash_data = nil
    @flags = nil
  end

  [:dispose, :disposed?, :update].each do |method|
    define_method(method) { @__handler__.send(method) }
  end

  def bitmaps
    @bitmaps
  end

  def map_data
    @map_data
  end

  def map_data=(map_data)
    check_arguments([map_data], [Table])
    @map_data = map_data
    @__handler__.map_data = map_data.__handler__
  end

  def flash_data
    @flash_data
  end

  def flash_data=(flash_data)
    check_arguments([flash_data], [Table])
    @flash_data = flash_data
    @__handler__.flash_data = flash_data.__handler__
  end

  def flags
    @flags
  end

  def flags=(flags)
    check_arguments([flags], [Table])
    @flags = flags
    @__handler__.flags = flags.__handler__
  end

  def viewport
    @viewport
  end

  def viewport=(viewport)
    check_arguments([viewport], [Viewport])
    @viewport = viewport
    @__handler__.viewport = viewport.__handler__
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

  [:ox, :oy, :visible].each do |prop|
    define_method(prop) { @__handler__.send(prop) }
    define_method("#{prop}=") { |value| @__handler__.send("#{prop}=", value) }
  end

  # Forwards indexed bitmap assignment to the native tilemap. Holds the Ruby Bitmap
  # wrappers so the getter can return them; the native side stores the underlying handle.
  class TilemapBitmapsProxy
    include TypeCheckUtil

    def initialize(handler)
      @__handler__ = handler
      @wrappers = Array.new(9)
    end

    def [](index)
      @wrappers[index]
    end

    def []=(index, bitmap)
      check_arguments([bitmap], [[Bitmap, NilClass]])
      @wrappers[index] = bitmap
      @__handler__.set_bitmap(index, bitmap&.__handler__)
    end
  end
end
