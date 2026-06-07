# encoding: utf-8
require 'type_check_util'

module Graphics
  extend TypeCheckUtil

  class << self
    DEFAULT_TYPE_CHECK_MAP = {
      frame_rate: Integer,
      frame_count: Integer,
      brightness: Integer,
    }

    DEFAULT_TYPE_CHECK_MAP.each do |prop, type|
      define_method(prop) do
        Unity::Graphics.send(prop)
      end
      define_method("#{prop}=") do |value|
        check_type(value, type)
        Unity::Graphics.send("#{prop}=", value)
      end
    end
  end

  def self.frame_rate
    Unity::Graphics.frame_rate
  end

  def self.frame_rate=(value)
    check_type(value, Integer)
    Unity::Graphics.frame_rate = value
  end

  def self.frame_count
    Unity::Graphics.frame_count
  end

  def self.frame_count=(value)
    check_type(value, Integer)
    Unity::Graphics.frame_count = value
  end

  def self.brightness
    Unity::Graphics.brightness
  end

  def self.brightness=(value)
    check_type(value, Integer)
    Unity::Graphics.brightness = value
  end

  def self.wait(duration)
    check_arguments([duration], [Integer])
    __rgss_frame_count(duration).times { update }
  end

  def self.fadeout(duration)
    check_arguments([duration], [Integer])
    duration = __rgss_frame_count(duration)
    Unity::Graphics.fadeout(duration)   # start the brightness ramp (C# animation state)
    wait(duration)                      # cooperative wait: one Fiber.yield per frame
  end

  def self.fadein(duration)
    check_arguments([duration], [Integer])
    duration = __rgss_frame_count(duration)
    Unity::Graphics.fadein(duration)
    wait(duration)
  end

  def self.play_movie(filename)
    check_arguments([filename], [String])
    Unity::Graphics.play_movie(filename)
  end

  def self.transition(duration = 10, filename = nil, vague = 40)
    check_arguments([duration, filename, vague], [Integer, [String, NilClass], Integer])
    duration = __rgss_frame_count(duration)
    Unity::Graphics.transition(duration, filename, vague)
    wait(duration)
  end

  def self.resize_screen(width = 1920, height = 1080)
    check_arguments([width, height], [Integer, Integer])
    Unity::Graphics.resize_screen(width, height)
  end
  
  def self.snap_to_bitmap
    Bitmap.new Unity::Graphics.snap_to_bitmap
  end

  # Clamp a frame-duration argument to a non-negative integer.
  def self.__rgss_frame_count(duration)
    duration = duration.to_i
    duration < 0 ? 0 : duration
  end

  # THE cooperative frame barrier. Native RGSS3 blocks one frame per Graphics.update;
  # this port runs the scene on a Fiber pumped once per Godot frame by _Process, so
  # Graphics.update advances the C# frame counter and then yields control back to the
  # pump (one Fiber.yield == one rendered frame). Every stock loop that uses
  # Graphics.update as its frame barrier (Scene_Base#main, fade_loop, battle waits,
  # rgss_stop, and third-party `loop { Graphics.update }`) therefore advances exactly
  # one frame per iteration with no per-callsite patching.
  def self.update
    Unity::Graphics.update
    Fiber.yield
    nil
  end

  [:freeze, :frame_reset, :width, :height].each do |method_name|
    define_singleton_method(method_name) do |*args|
      Unity::Graphics.send(method_name, *args)
    end
  end
end