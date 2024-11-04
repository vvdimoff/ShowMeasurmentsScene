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
  
    def self.find_holes(group)
      puts "\nПоиск отверстий в детали: #{group.name}"
      
      holes = []
      hole_groups = find_hole_groups(group)
      
      puts "Найдено групп отверстий: #{hole_groups.length}"
      
      hole_groups.each do |hole_group|
        find_hole_info(hole_group, holes)
      end
      
      if holes.empty?
        puts "Отверстия не найдены"
        return
      end

      puts "\nНайденные отверстия:"
      holes.each do |hole_data|
        puts "- Диаметр: #{hole_data[:diameter]}мм, Глубина: #{hole_data[:depth]}мм"
      end
    end
  
    private
  
    def self.find_abf_label(group)
      # Рекурсивный поиск грппы _ABF_Label
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
  
    def self.find_hole_groups(entity, groups = [])
      if entity.is_a?(Sketchup::Group)
        if entity.name == "ABF_Hole"
          groups << entity
        else
          entity.entities.each { |e| find_hole_groups(e, groups) }
        end
      elsif entity.is_a?(Sketchup::ComponentInstance)
        find_hole_groups(entity.definition, groups)
      end
      groups
    end
  
    def self.find_hole_info(hole_group, holes)
      puts "\nПроверка группы отверстия: #{hole_group.name}"
      
      circle = hole_group.entities.find { |e| e.is_a?(Sketchup::Edge) && e.curve.is_a?(Sketchup::ArcCurve) }
      center_point = hole_group.entities.find { |e| e.is_a?(Sketchup::ConstructionPoint) }
      
      if circle && center_point
        # Преобразуем локальные координаты в глобальные
        transformation = hole_group.transformation
        global_center = center_point.position.transform(transformation)
        
        tag = circle.layer.name
        puts "Найдена окружность:"
        puts "  Радиус: #{circle.curve.radius}мм"
        puts "  Тег: #{tag}"
        puts "  Центральная точка (глобальные координаты): #{global_center}"
        
        if tag && tag.match(/D(\d+\.?\d*)_DEPTH(\d+\.?\d*)/)
          diameter = $1.to_f
          depth = $2.to_f
          hole_info = { diameter: diameter, depth: depth }
          holes << hole_info
          puts "\nНайдено отверстие: D#{diameter}_DEPTH#{depth}"
          
          # Получаем родительскую деталь
          parent_group = hole_group.parent
          if parent_group
            # Ищем группу размеров
            dimensions_group = parent_group.entities.find { |e| 
              e.is_a?(Sketchup::Group) && e.name == "Размеры" 
            }
            
            unless dimensions_group
              puts "Группа 'Размеры' не найдена"
              return
            end
            
            # Ищем ближайшие грани, образующие угол
            faces = find_all_faces(parent_group)
            closest_faces = find_corner_faces(global_center, faces)
            
            if closest_faces[:x] && closest_faces[:y]
              create_dimensions(dimensions_group, global_center, closest_faces, hole_info)
            end
          end
        end
      end
    end
  
    # Вспомогательный метод для отладки
    def self.debug_print_structure(entity, level = 0)
      indent = "  " * level
      if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        puts "#{indent}+ #{entity.class}: #{entity.name}"
        entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
        entities.each { |e| debug_print_structure(e, level + 1) }
      else
        puts "#{indent}- #{entity.class}"
      end
    end
  
    def self.find_all_faces(group)
      faces = []
      group.entities.each do |entity|
        if entity.is_a?(Sketchup::Face)
          faces << entity
        elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          faces.concat(find_all_faces(entity.respond_to?(:definition) ? entity.definition : entity))
        end
      end
      faces
    end
  
    def self.find_closest_faces(point, faces)
      result = { x: nil, y: nil }
      min_x_dist = Float::INFINITY
      min_y_dist = Float::INFINITY
      
      faces.each do |face|
        normal = face.normal
        # Проверяем только вертикальные грани
        next unless normal.z.abs < 0.1
        
        # Определяем, это грань X или Y по нормали
        if normal.x.abs > normal.y.abs
          # Расстояние до грани по X
          dist = (face.bounds.min.x - point.x).abs
          if dist < min_x_dist
            min_x_dist = dist
            result[:x] = { face: face, distance: dist }
          end
        else
          # Расстояние до грани по Y
          dist = (face.bounds.min.y - point.y).abs
          if dist < min_y_dist
            min_y_dist = dist
            result[:y] = { face: face, distance: dist }
          end
        end
      end
      
      result
    end
  
    def self.find_corner_faces(point, faces)
      result = { x: nil, y: nil }
      min_x_dist = Float::INFINITY
      min_y_dist = Float::INFINITY
      
      # Сначала найдем все вертикальные грани
      vertical_faces = faces.select { |face| face.normal.z.abs < 0.1 }
      
      vertical_faces.each do |face|
        normal = face.normal
        
        # Для каждой точки грани
        face.vertices.each do |vertex|
          if normal.x.abs > normal.y.abs
            # Это грань, перпендикулярная оси X
            dist = (vertex.position.x - point.x).abs
            if dist < min_x_dist
              min_x_dist = dist
              result[:x] = { 
                face: face,
                distance: dist,
                point: vertex.position
              }
            end
          else
            # Это грань, перпендикулярная оси Y
            dist = (vertex.position.y - point.y).abs
            if dist < min_y_dist
              min_y_dist = dist
              result[:y] = { 
                face: face,
                distance: dist,
                point: vertex.position
              }
            end
          end
        end
      end
      
      result
    end
  
    def self.create_dimensions(dimensions_group, global_center, closest_faces, hole_info)
      model = Sketchup.active_model
      model.start_operation('Create Hole Dimensions', true)
      
      begin
        # Создаем размеры (существующий код)
        dimensions = {
          x: {
            face: closest_faces[:x][:face],
            vector: Geom::Vector3d.new(0, 1, 0)
          },
          y: {
            face: closest_faces[:y][:face],
            vector: Geom::Vector3d.new(1, 0, 0)
          }
        }
        
        dimensions.each do |axis, data|
          face_point = if axis == :x
            Geom::Point3d.new(data[:face].bounds.min.x, global_center.y, global_center.z)
          else
            Geom::Point3d.new(global_center.x, data[:face].bounds.min.y, global_center.z)
          end
          
          dim = dimensions_group.entities.add_dimension_linear(
            global_center,
            face_point,
            data[:vector]
          )
          puts "Создан размер по #{axis} в группе 'Размеры'"
        end
        
        # Добавляем текст с информацией об отверстии
        text = "D#{hole_info[:diameter]};H#{hole_info[:depth]}"
        
        # Вычисляем вектор направления к ближайшим граням
        x_direction = global_center.x > closest_faces[:x][:face].bounds.min.x ? 1 : -1
        y_direction = global_center.y > closest_faces[:y][:face].bounds.min.y ? 1 : -1
        
        # Создаем вектор смещения
        offset_vector = Geom::Vector3d.new(
          x_direction,
          y_direction,
          0
        ).normalize!
        
        # Создаем точку для текста
        offset = 35.mm
        text_point = Geom::Point3d.new(
          global_center.x + (offset_vector.x * offset),
          global_center.y + (offset_vector.y * offset),
          global_center.z
        )
        
        # Создаем выносную линию
        line = dimensions_group.entities.add_line(global_center, text_point)
        
        # Добавляем текст
        dimensions_group.entities.add_text(text, text_point)
        
        puts "Добавлен текст: #{text}"
        
        model.commit_operation
      rescue => e
        puts "Ошибка при создании размеров: #{e.message}"
        model.abort_operation
      end
    end
  end
  