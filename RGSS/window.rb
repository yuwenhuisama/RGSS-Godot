# encoding: utf-8
require 'type_check_util'

class Window
  include TypeCheckUtil

  attr_reader :__handler__

  def initialize(x = 0, y = 0, width = 0, height = 0)
    check_arguments([x, y, width, height], [[Integer, Float], [Integer, Float], Integer, Integer])
    @__handler__ = Unity::Window.new_xywh(x, y, width, height, Viewport::DEFAULT_VIEWPORT.__handler__)
    self.cursor_rect = Rect.create_default_rect
    self.contents = Bitmap.create_default_bitmap
    self.padding = 8
    self.padding_bottom = 8
  end

  def move(x, y, w, h)
    check_arguments([x, y, w, h], [[Integer, Float], [Integer, Float], Integer, Integer])
    @__handler__.move(x, y, w, h)
  end

  def windowskin
    handler = @__handler__.windowskin
    handler.nil? ? nil : (@windowskin ||= Bitmap.new(handler))
  end

  def windowskin=(bitmap)
    check_arguments([bitmap], [[Bitmap, NilClass]])
    @__handler__.windowskin = bitmap&.__handler__
    @windowskin = bitmap
  end

  def contents
    @contents ||= Bitmap.new(@__handler__.contents)
  end

  def contents=(contents)
    check_arguments([contents], [Bitmap])
    @__handler__.contents = contents.__handler__
    @contents = contents
  end

  def cursor_rect
    @cursor_rect ||= Rect.new(@__handler__.cursor_rect)
  end

  def cursor_rect=(rect)
    check_arguments([rect], [Rect])
    @__handler__.cursor_rect = rect.__handler__
    @cursor_rect = rect
  end

  def viewport
    return @viewport if @viewport
    if @__handler__.viewport == Viewport::DEFAULT_VIEWPORT.__handler__
      nil
    else
      Viewport.new @__handler__.viewport
    end
  end

  def viewport=(viewport)
    check_arguments([viewport], [[Viewport, NilClass]])
    @__handler__.viewport = (viewport || Viewport::DEFAULT_VIEWPORT).__handler__
    @viewport = viewport
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

  def opacity=(opacity)
    check_type(opacity, Integer)
    self.__handler__.opacity = opacity.clamp(0, 255)
  end

  def opacity
    self.__handler__.opacity
  end

  def back_opacity=(back_opacity)
    check_type(back_opacity, Integer)
    self.__handler__.back_opacity = back_opacity.clamp(0, 255)
  end

  def back_opacity
    self.__handler__.back_opacity
  end

  def contents_opacity=(contents_opacity)
    check_type(contents_opacity, Integer)
    self.__handler__.contents_opacity = contents_opacity.clamp(0, 255)
  end

  def contents_opacity
    self.__handler__.contents_opacity
  end

  def openness=(openness)
    check_type(openness, Integer)
    self.__handler__.openness = openness.clamp(0, 255)
  end

  def openness
    self.__handler__.openness
  end

  def width=(width)
    check_type(width, Integer)
    if width < 0
      raise ArgumentError.new("width must be positive")
    end
    self.__handler__.width = width
  end

  def width
    self.__handler__.width
  end

  def height=(height)
    check_type(height, Integer)
    if height < 0
      raise ArgumentError.new("height must be positive")
    end
    self.__handler__.height = height
  end
  
  def height
    self.__handler__.height
  end
  
  def tone
    @tone ||= Tone.new(@__handler__.tone)
  end
  
  def tone=(tone)
    check_arguments([tone], [Tone])
    @__handler__.tone = tone.__handler__
    @tone = tone
  end

  [:dispose, :disposed?, :update, :open?, :close?].each do |method|
    define_method(method) do |*args|
      @__handler__.send(method, *args)
    end
  end

  TYPE_CHECK_MAP = {
    :active => [TrueClass, FalseClass],
    :visible => [TrueClass, FalseClass],
    :arrows_visible => [TrueClass, FalseClass],
    :pause => [TrueClass, FalseClass],
    :x => [Integer, Float],
    :y => [Integer, Float],
    :z => Integer,
    :ox => [Integer, Float],
    :oy => [Integer, Float],
    :padding => Integer,
    :padding_bottom => Integer,
  }

  TYPE_CHECK_MAP.each do |prop, type|
    define_method(prop) do
      @__handler__.send(prop)
    end
    define_method("#{prop}=") do |value|
      check_type(value, type)
      @__handler__.send("#{prop}=", value)
    end
  end
end

require 'resource_lifecycle'
ResourceLifecycle.guard(Window)
