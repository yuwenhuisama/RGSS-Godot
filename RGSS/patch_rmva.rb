# encoding: utf-8
module SceneManager
  def self.run
    DataManager.init
    Audio.setup_midi if use_midi?
    @scene = first_scene_class.new

    @update_fiber = Fiber.new do
      begin
        @scene.main while @scene
      rescue Exception => e
        str = format_exc_string(e)
        Unity.on_top_exception(str)
      end
      Unity.unregister_update_fiber
    end

    Unity.register_update_fiber @update_fiber
  end
end

# NOTE: the cooperative frame barrier now lives in Graphics.update (RGSS/graphics.rb),
# which calls Unity::Graphics.update then Fiber.yield. Because every RGSS3 frame loop
# (Scene_Base#main's `update until scene_changing?`, Scene_Map fade_loop, Scene_Battle
# wait helpers, rgss_stop, and third-party `loop { Graphics.update }`) ultimately calls
# Graphics.update once per iteration, stock scene code runs unmodified at the correct
# one-frame-per-iteration cadence. The previous per-callsite Fiber.yield patches
# (Scene_Base#__yield_update, Scene_Title/Scene_End#close_command_window,
# Scene_Map#update_for_fade, Scene_Battle#update_for_wait/process_event) are no longer
# needed and have been removed to avoid double-yielding (which would halve the frame
# rate).

module DataManager
  def self.__get_real_path__(*path)
    File.join($rmva_project_base_path, "RMProject", *path)
  end

  def self.__get_rtp_path__(*path)
    File.join($rtp_path, *path)
  end

  class << self
    alias :old_save_file_exists? :save_file_exists?

    def save_file_exists?
      path = __get_real_path__('Save*.rvdata2')
      !Dir.glob(path).empty?
    end

    alias :old_make_filename :make_filename

    def make_filename(index)
      filename = old_make_filename(index)
      __get_real_path__(filename)
    end
  end
end

module Audio
  class << self
    alias :old_bgm_play :bgm_play

    def bgm_play(filename, volume = 100, pitch = 100, pos = 0)
      unless filename.include?('.')
        filename = filename + ".ogg"
      end
      path = DataManager.__get_real_path__(filename)
      old_bgm_play(path, volume, pitch, pos, proc {
        rtp_path = DataManager.__get_rtp_path__(filename)
        old_bgm_play(rtp_path, volume, pitch, pos)
      })
    end

    alias :old_bgs_play :bgs_play

    def bgs_play(filename, volume = 100, pitch = 100, pos = 0)
      unless filename.include?('.')
        filename = filename + ".ogg"
      end
      path = DataManager.__get_real_path__(filename)
      old_bgs_play(path, volume, pitch, pos, proc {
        rtp_path = DataManager.__get_rtp_path__(filename)
        old_bgs_play(rtp_path, volume, pitch, pos)
      })
    end

    alias :old_me_play :me_play

    def me_play(filename, volume = 100, pitch = 100)
      unless filename.include?('.')
        filename = filename + ".ogg"
      end
      path = DataManager.__get_real_path__(filename)
      old_me_play(path, volume, pitch, proc {
        rtp_path = DataManager.__get_rtp_path__(filename)
        old_me_play(rtp_path, volume, pitch)
      })
    end

    alias :old_se_play :se_play

    def se_play(filename, volume = 100, pitch = 100)
      unless filename.include?('.')
        filename = filename + ".ogg"
      end
      path = DataManager.__get_real_path__(filename)
      old_se_play(path, volume, pitch, proc {
        rtp_path = DataManager.__get_rtp_path__(filename)
        old_se_play(rtp_path, volume, pitch)
      })
    end
  end
end

module Cache
  class << self
    alias :old_load_bitmap :load_bitmap

    def load_bitmap(folder_name, filename, hue = 0)
      # Empty tileset slots (e.g. a dungeon set with no A3/D/E) pass an empty name.
      # RGSS3 returns a blank bitmap for these rather than attempting a file load.
      if filename.nil? || filename.empty?
        return Bitmap.new(32, 32)
      end
      unless filename.include?('.')
        filename = filename + ".png"
      end
      # RTP fallback must be decided HERE in Ruby: a missing-file RGSSError raised
      # from the C# Bitmap.new binding cannot be caught by `rescue` across the
      # mruby-dotnet callback boundary. Probe both candidate paths with the
      # non-raising Unity::Bitmap.file_exists? binding, then load from whichever
      # exists (defaulting to the RTP path so the final failure still comes from
      # Bitmap.new with a real error message).
      real_path = DataManager.__get_real_path__(folder_name)
      if Unity::Bitmap.file_exists?(real_path + filename)
        old_load_bitmap(real_path, filename, hue)
      else
        rtp_path = DataManager.__get_rtp_path__(folder_name)
        old_load_bitmap(rtp_path, filename, hue)
      end
    end
  end
end

# ----------------------------------------------------------------------------
# MRI-compatible Array#sort / #sort! comparator semantics
# ----------------------------------------------------------------------------
# Our host mruby's native Array#sort!/#sort require the comparator block to
# return an Integer; a Float result raises
#   ArgumentError: comparison failed (element N and M)
# (Still true on mruby 4.0.0 -- verified -- unlike the do-while and UTF-8
# workarounds which 4.0.0 made unnecessary.)
# MRI/CRuby (which real RGSS3 targets) instead routes the comparator result
# through rb_cmpint, which only inspects the SIGN (`> 0` / `< 0`), so Float,
# Integer and Bignum results are all valid and only nil is rejected. Stock RMVA
# relies on this, e.g. BattleManager#make_action_orders does
#   @action_battlers.sort! {|a, b| b.speed - a.speed }
# where speed is a Float (Game_Action#speed adds atk_speed, itself a
# features_sum_all -> inject(0.0) Float), which crashes on the native sort.
#
# Restore MRI semantics at the primitive so stock RMVA (and any custom game
# script using a difference comparator) works unchanged: coerce the block's
# result to -1/0/+1 by sign before handing it to the native sort. This mirrors
# rb_cmpint exactly -- including treating Float::NAN as 0 (a `<=> 0` coercion
# would wrongly map NaN to nil and raise), while a genuine nil still raises like
# MRI. Only sort/sort! need this; min/max/minmax and *_by compare with `<=>`/`>`
# directly and already tolerate Floats (verified).
class Array
  unless method_defined?(:__rgss_mri_sort_bang__)
    alias_method :__rgss_mri_sort_bang__, :sort!
    alias_method :__rgss_mri_sort__, :sort
  end

  # rb_cmpint equivalent: reduce a comparator result to its sign as an Integer.
  def __rgss_mri_cmpint__(v)
    return nil if v.nil?
    return 1 if v > 0
    return -1 if v < 0
    0
  end

  def sort!(&block)
    return __rgss_mri_sort_bang__ unless block
    __rgss_mri_sort_bang__ {|a, b| __rgss_mri_cmpint__(block.call(a, b)) }
  end

  def sort(&block)
    return __rgss_mri_sort__ unless block
    __rgss_mri_sort__ {|a, b| __rgss_mri_cmpint__(block.call(a, b)) }
  end
end
