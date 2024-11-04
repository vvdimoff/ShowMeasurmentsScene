require 'sketchup.rb'
require 'extensions.rb'

module ShowMeasuresScene
  module ContextMenu

    unless file_loaded?(__FILE__)
      ex = SketchupExtension.new('Show Measures Scene', 'ShowMeasuresScene/main')
      ex.description = 'Display a scene showing measures for a specific group within ABF_Flatten.'
      ex.version     = '1.0.0'
      ex.copyright   = 'Ivanka.com.ua'
      ex.creator     = 'Meetda (https://Ivanka.com.ua)'

      Sketchup.register_extension(ex, true)
      file_loaded(__FILE__)
    end

  end # module ContextMenu
end # module ShowMeasuresScene
