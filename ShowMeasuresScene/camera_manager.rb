module ShowMeasuresScene
    module CameraManager
      # Центрирует камеру на группе
      def self.center_on_group(group)
        model = Sketchup.active_model
        view = model.active_view
        bounds = group.bounds
        center = bounds.center
        normal = Geom::Vector3d.new(0, 0, 1)
  
        # Проверка центра и нормали
        puts "Centering camera on group: #{group.name}"
        puts "BoundingBox center: #{center}"
        puts "Using normal vector: #{normal}"
  
        begin
          eye = center.offset(normal, 50)  # Уменьшаем отступ камеры с 200 до 50
          target = center
          up = Geom::Vector3d.new(0, 1, 0) # Задание верхнего направления для ориентации камеры
  
          view.camera.set(eye, target, up)
          puts "Camera successfully centered on group: #{group.name}"
        rescue => e
          puts "Error centering camera: #{e.message}"
        end
      end
    end
  end
  