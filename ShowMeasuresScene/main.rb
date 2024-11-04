# main.rb
load File.join(__dir__, 'context_menu_handler.rb')
load File.join(__dir__, 'scene_manager.rb')
load File.join(__dir__, 'visibility_handler.rb')
load File.join(__dir__, 'camera_manager.rb')
load File.join(__dir__, 'dimension_manager.rb')

module ShowMeasuresScene
  module Main
    def self.init
      # Инициализируем контекстное меню
      ContextMenuHandler.add_context_menu
    end
  end
end

ShowMeasuresScene::Main.init

