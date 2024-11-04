module ShowMeasuresScene
  module VisibilityHandler
    # Скрывает все элементы в модели
    def self.hide_all(model)
      model.entities.each do |entity|
        if entity.respond_to?(:visible=)
          entity.visible = false
        end
      end
      puts "All elements hidden"
    end

    # Проходит по иерархии от группы к корневой модели и делает видимыми все элементы на пути
    def self.make_hierarchy_visible(entity)
      current_entity = entity
      puts "Making hierarchy visible from '#{entity.name}' to root model:"

      while current_entity
        if current_entity.is_a?(Sketchup::ComponentInstance) || current_entity.is_a?(Sketchup::Group)
          puts "Setting visible: #{current_entity.name} (#{current_entity.class}) - ID: #{current_entity.entityID}"
          current_entity.visible = true
          current_entity = current_entity.parent
        elsif current_entity.is_a?(Sketchup::Model)
          puts "Reached model root, visibility path completed"
          break
        else
          if current_entity.is_a?(Sketchup::ComponentDefinition)
            instance = current_entity.instances.first
            if instance
              puts "Setting visible: Instance of #{current_entity.name} (#{instance.class}) - ID: #{instance.entityID}"
              instance.visible = true
              current_entity = instance.parent
            else
              puts "No instances found for definition: #{current_entity.name}"
              break
            end
          else
            puts "Unknown Entity Type: #{current_entity.class}"
            break
          end
        end
      end
    end
  end
end
