module ShowMeasuresScene
  module ContextMenuHandler
    @menu_handler_added = false  # Флаг для отслеживания добавления обработчика

    def self.add_context_menu
      return if @menu_handler_added  # Если обработчик уже добавлен, выходим
      
      UI.add_context_menu_handler do |menu|
        model = Sketchup.active_model
        selected_entity = model.selection.first
        current_scene = model.pages.selected_page

        # Проверка, является ли выбранный элемент нужной группой с префиксом "__"
        # и текущая сцена не является сценой детали
        if selected_entity.is_a?(Sketchup::Group) && 
           selected_entity.name.start_with?("__") && 
           (current_scene.nil? || !current_scene.name.include?("Measure Scene"))
          
          parent_component = find_abf_flatten_parent(selected_entity)

          # Если выбрана подходящая группа, добавляем пункт меню
          if parent_component
            menu.add_item("Show measures scene") do
              handle_show_measures_scene(selected_entity)
            end
          end
        end
      end

      @menu_handler_added = true  # Устанавливаем флаг, чтобы обработчик добавлялся только один раз
    end

    # Обработка нажатия на пункт меню
    def self.handle_show_measures_scene(group)
      # Обновляем или создаем главную сцену
      if !main_scene_exists?
        ShowMeasuresScene::SceneManager.create_main_scene
      else
        ShowMeasuresScene::SceneManager.update_main_scene
      end

      # Создаем или обновляем сцену для выбранной детали
      scene_name = "Measure Scene for #{group.name}"
      puts "Creating or updating scene named '#{scene_name}' for group '#{group.name}'"
      ShowMeasuresScene::SceneManager.create_measure_scene(group)
    end

    # Проверка существования главной сцены
    def self.main_scene_exists?
      Sketchup.active_model.pages.any? { |page| page.name == "Main" }
    end

    def self.find_abf_flatten_parent(entity)
      current_entity = entity
      while current_entity
        parent = current_entity.parent
        return current_entity if parent.is_a?(Sketchup::ComponentDefinition) && parent.name.include?("THICKNESS_")
        current_entity = parent.respond_to?(:parent) ? parent : nil
      end
      nil
    end

    # Инициализация обработчика
    unless file_loaded?(__FILE__)
      add_context_menu
      file_loaded(__FILE__)
    end
  end
end
