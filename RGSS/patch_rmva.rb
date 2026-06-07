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

# UTF-8-aware per-character text rendering. The embedded mruby host VM is byte-based
# (no MRB_UTF8_STRING): String#length, #slice, #[], #each_char all operate on BYTES, so
# Window_Base#draw_text_ex's `text.slice!(0, 1)` would feed a single byte of a multibyte
# (3-byte UTF-8) CJK character to draw_text, producing mojibake. (Menus look fine because
# they draw whole strings via draw_text, never slicing per character.) Re-implement the
# per-character walk by decoding UTF-8 character boundaries from the leading byte via
# getbyte/byteslice (both confirmed byte-exact on this VM), so each draw_text receives a
# complete character.
class Window_Base
  # Number of bytes in the UTF-8 character whose leading byte is `b`.
  def __utf8_char_len(b)
    return 1 if b.nil?
    if b < 0x80 then 1
    elsif b < 0xC0 then 1      # stray continuation byte: treat as 1 (defensive)
    elsif b < 0xE0 then 2
    elsif b < 0xF0 then 3
    elsif b < 0xF8 then 4
    else 1
    end
  end

  # Slice and remove the first whole UTF-8 character from `text` (mutating it), returning
  # that character. Mirrors text.slice!(0, 1) but character- not byte-wise.
  def __utf8_shift_char!(text)
    n = __utf8_char_len(text.getbyte(0))
    ch = text.byteslice(0, n)
    text.replace(text.byteslice(n, text.bytesize - n) || "")
    ch
  end

  def draw_text_ex(x, y, text)
    reset_font_settings
    text = convert_escape_characters(text)
    pos = { :x => x, :y => y, :new_x => x, :height => calc_line_height(text) }
    process_character(__utf8_shift_char!(text), text, pos) until text.empty?
  end
end

# Window_Message has its OWN per-character loop (process_all_text) that does NOT go
# through draw_text_ex, so it needs the same UTF-8-aware character walk to avoid mojibake
# on multibyte (CJK) message text.
class Window_Message
  def process_all_text
    open_and_wait
    text = convert_escape_characters($game_message.all_text)
    pos = {}
    new_page(text, pos)
    process_character(__utf8_shift_char!(text), text, pos) until text.empty?
  end
end

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
# mruby 3.3.0 do-while back-edge dispatch workaround
# ----------------------------------------------------------------------------
# Our host mruby is 3.3.0. It has a VM bug where the receiver register used by
# the `OP_SEND` at the back-edge condition of a `begin ... end until <recv>.<m>`
# do-while loop can be stale, so the condition send raises a spurious
# `NoMethodError` even though the method is defined and resolves fine via a
# direct call / send / method() / respond_to? on the very same object. (Fixed
# upstream in mruby 3.4.0 by commit 0337e0e0 / PR #6427 "update `ci` after
# re-entry to VM"; we cannot bump the native VM yet because MRuby.Library 0.1.8
# binds the 3.3.0 ABI.)
#
# Symptom we hit: selecting "Fight" in battle -> BattleManager.next_command ->
#   `end until actor.inputable?` raised "undefined method 'inputable?'".
#
# Workaround: rewrite the affected stock-RMVA do-while loops in the equivalent
# `loop do ... break if ...` form, which compiles to a front-tested loop whose
# condition send reads a fresh receiver register. Semantics are preserved.
# Receiver is hoisted to a local and nil-guarded (a nil here would have crashed
# the original `actor.inputable?` too, so this only widens safety).
module BattleManager
  def self.next_command
    loop do
      if !actor || !actor.next_command
        @actor_index += 1
        return false if @actor_index >= $game_party.members.size
      end
      cur = actor
      break if cur && cur.inputable?
    end
    return true
  end

  def self.prior_command
    loop do
      if !actor || !actor.prior_command
        @actor_index -= 1
        return false if @actor_index < 0
      end
      cur = actor
      break if cur && cur.inputable?
    end
    return true
  end
end

class Game_Interpreter
  # Stock: `begin; @index -= 1; end until @list[@index].indent == @indent`
  # (event command 413 "Repeat Above"). Same do-while-with-condition-send shape;
  # rewritten defensively for the same mruby 3.3.0 reason.
  def command_413
    loop do
      @index -= 1
      break if @list[@index].indent == @indent
    end
  end
end
