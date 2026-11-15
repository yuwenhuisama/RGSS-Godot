# encoding: utf-8
module Kernel
  def run_rgss_main_callback
    begin
      $rgss_main_callback.call if $rgss_main_callback
    rescue RGSSReset
      Unity.reset_rgss_resources
      retry
    end
  end
  def rgss_main(&callback)
    $rgss_main_callback = callback
  end

  def rgss_stop
    # Native RGSS3 semantics: idle forever, advancing one frame per iteration, until
    # an RGSSReset (F12) is raised. Graphics.update is the cooperative frame barrier
    # (it yields the scene fiber back to the per-frame pump), so this loop is a proper
    # one-yield-per-frame idle rather than a busy spin.
    loop { Graphics.update }
  end

  def load_data(filename)
    file_full_path = File.join($rmva_project_base_path, "RMProject", filename)
    File.open(file_full_path, "rb") do |f|
      Marshal.load(f)
    end
  end

  def save_data(obj, filename)
    file_full_path = File.join($rmva_project_base_path, "RMProject", filename)
    File.open(file_full_path, "wb") do |f|
      Marshal.dump(obj, f)
    end
  end

  def msgbox(*args)
    Unity.msgbox(*args)
  end

  def msgbox_p(*args)
    msgbox(*args)
  end
end
