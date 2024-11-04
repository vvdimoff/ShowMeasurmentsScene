module ShowMeasuresScene
    module SceneManager
      def self.create_main_scene
        model = Sketchup.active_model
        main_scene = model.pages["Main"] || model.pages.add("Main")
        model.pages.selected_page = main_scene
        main_scene.update
        puts "Created or updated main scene: 'Main'"
      end
  
      def self.create_measure_scene(group)
        model = Sketchup.active_model
        scene_name = "Measure Scene for #{group.name}"
  
        # Проверяем наличие сцены
        scene = model.pages[scene_name] || model.pages.add(scene_name)
        model.pages.selected_page = scene
  
        # Скрываем все элементы и делаем видимыми только необходимые
        VisibilityHandler.hide_all(model)
        VisibilityHandler.make_hierarchy_visible(group)
  
        # Центрируем вид на группе
        CameraManager.center_on_group(group)
  
        # Добавляем размеры к лицевой стороне группы
        DimensionManager.add_dimensions_to_group(group)
  
        # Добавляем поиск отверстий
        DimensionManager.find_holes(group)
  
        # Обновляем сцену для сохранения настроек
        scene.update
        puts "Created or updated scene named '#{scene_name}' for group '#{group.name}'"
      end
  
      def self.update_main_scene
        model = Sketchup.active_model
        main_scene = model.pages["Main"] || model.pages.add("Main")
        model.pages.selected_page = main_scene
        main_scene.update
        puts "Updating existing main scene: 'Main'"
      end
    end
  end
  