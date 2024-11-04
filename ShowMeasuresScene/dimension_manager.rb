# dimension_manager.rb

module DimensionManager
    # Добавляем размеры к каждой грани в плоскости XY, параллельной детали
    def self.add_dimensions_to_group(group)
      # Создаем группу для размеров внутри переданной группы
      dimensions_group = group.entities.add_group
      dimensions_group.name = "Размеры"
  
      # Находим _ABF_Label в группе
      puts "Searching for _ABF_Label in group: #{group.name}"
      abf_label = find_abf_label(group)
      return unless abf_label
  
      # Используем грань, на которой находится _ABF_Label
      face = find_face_with_label(group, abf_label)
      return unless face
  
      bounds = face.bounds
      
      # Получаем точки для размеров
      width_start = Geom::Point3d.new(bounds.min.x, bounds.min.y, bounds.max.z)
      width_end = Geom::Point3d.new(bounds.max.x, bounds.min.y, bounds.max.z)
      height_start = Geom::Point3d.new(bounds.max.x, bounds.min.y, bounds.max.z)
      height_end = Geom::Point3d.new(bounds.max.x, bounds.max.y, bounds.max.z)
  
      # Векторы смещения остаются те же
      width_offset = Geom::Vector3d.new(0, -30.mm, 0)
      height_offset = Geom::Vector3d.new(30.mm, 0, 0)
  
      add_dimension(dimensions_group.entities, width_start, width_end, width_offset)
      add_dimension(dimensions_group.entities, height_start, height_end, height_offset)
    end
  
    # Функция для добавления линейного размера
    def self.add_dimension(entities, pt1, pt2, offset)
      # Проверяем, что точки не совпадают, чтобы избежать ошибок
      return if pt1 == pt2
      entities.add_dimension_linear(pt1, pt2, offset)
    end
  
    private
  
    def self.find_abf_label(group)
      # Рекурсивный поиск группы _ABF_Label
      label = nil
      group.entities.each do |entity|
        if entity.is_a?(Sketchup::Group) && entity.name == "_ABF_Label"
          return entity
        elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          label = find_abf_label(entity.definition) if entity.respond_to?(:definition)
          return label if label
        end
      end
      nil
    end
  
    def self.find_face_with_label(group, label)
      # Находим грань, на которой расположен _ABF_Label
      label_bounds = label.bounds
      label_center = label_bounds.center
  
      faces = group.entities.grep(Sketchup::Face)
      faces.find do |face|
        # Проверяем, что точка центра метки лежит на грани или очень близко к ней
        face.classify_point(label_center) <= 2  # 2 = POINT_ON_FACE в API SketchUp
      end
    end
  end
  