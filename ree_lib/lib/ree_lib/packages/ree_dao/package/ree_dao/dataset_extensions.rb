# frozen_string_literal: true

module ReeDao
  module DatasetExtensions
    def self.included(base)
      alias_methods(base)
      base.include(InstanceMethods)
    end

    def self.extended(base)
      alias_methods(base)
      base.include(InstanceMethods)
    end

    def self.alias_methods(base)
      [:all, :update, :delete, :first, :last].each do |m|
        base.alias_method(:"__original_#{m}", m)
      end
    end

    module InstanceMethods
      PERSISTENCE_STATE_VARIABLE = :@persistence_state
      IMPORT_BATCH_SIZE = 1000

      # override methods
      def find(id, mode = :write, mapper: nil)
        where(primary_key => id).first(mode, mapper: mapper)
      end

      def first(mode = :write, mapper: nil)
        with_mapper(mode, mapper).__original_first
      end

      def last(mode = :write, mapper: nil)
        with_mapper(mode, mapper).__original_last
      end

      def all(mode = :write, mapper: nil)
        with_mapper(mode, mapper).__original_all
      end

      def delete_all
        where({}).__original_delete
      end

      def put(entity)
        raw = opts[:schema_mapper].db_dump(entity)
        remove_null_primary_key(raw)
        key = insert(raw)

        set_entity_primary_key(entity, raw, key)
        set_persistence_state(entity, raw)

        entity
      end

      def put_with_conflict(entity, conflict_opts = {})
        raw = opts[:schema_mapper].db_dump(entity)
        remove_null_primary_key(raw)

        if conflict_opts.key?(:update) && conflict_opts[:update].empty?
          conflict_opts.delete(:update)
        elsif conflict_opts[:update].is_a?(Array)
          update = {}

          conflict_opts[:update].each do |column|
            update[column] = raw[column]
          end

          conflict_opts[:update] = update
        end

        key = insert_conflict(conflict_opts).insert(raw)

        set_entity_primary_key(entity, raw, key)
        set_persistence_state(entity, raw)

        where(primary_key => key).first
      end

      def import_all(entities, batch_size: IMPORT_BATCH_SIZE)
        return if entities.empty?

        mapper = opts[:schema_mapper]
        columns = columns
        raw = {}

        columns.delete(:id)
        columns.delete(:row)

        data = entities.map do |entity|
          hash = mapper.to_hash(entity)
          raw[entity] = hash

          columns.map { hash[_1] }
        end

        ids = import(
          columns, data, slice: batch_size, return: :primary_key
        )

        ids.each_with_index do |id, index|
          entity = entities[index]
          raw_data = raw[entity]

          set_entity_primary_key(entity, raw_data, id)
          set_persistence_state(entity, raw_data)
        end

        nil
      end

      def update(entity)
        if opts[:schema_mapper]
          raw = opts[:schema_mapper].db_dump(entity)
          raw = extract_changes(entity, raw)

          unless raw.empty?
            update_persistence_state(entity, raw)
            key_condition = prepare_key_condition_from_entity(entity)
            where(key_condition).__original_update(raw)
          end

          entity
        else
          __original_update(entity)
        end
      end

      def delete(entity = nil)
        if entity
          key_condition = prepare_key_condition_from_entity(entity)
          where(key_condition).__original_delete
        else
          __original_delete
        end
      end

      def with_lock
        for_update
      end

      private

      def primary_key
        opts[:primary_key] || :id
      end

      def remove_null_primary_key(raw)
        return if primary_key.is_a?(Array)

        if raw.has_key?(primary_key) && raw[primary_key].nil?
          raw.delete(primary_key)
        else
          str_key = primary_key.to_s

          if raw.has_key?(str_key) && raw[str_key].nil?
            raw.delete(str_key)
          end
        end
      end

      def with_mapper(mode, mapper)
        clone(
          mode: mode, schema_mapper: mapper || opts[:schema_mapper],
        ).with_row_proc(
          Proc.new { |hash|
            m = mapper || opts[:schema_mapper]

            if m
              entity = m.db_load(hash)

              if mode == :write
                self.set_persistence_state(entity, hash)
              end

              entity
            else
              hash
            end
          }
        )
      end

      def extract_changes(entity, hash)
        return hash unless entity.instance_variable_defined?(PERSISTENCE_STATE_VARIABLE)
        changes = {}

        persistence_state = entity.instance_variable_get(PERSISTENCE_STATE_VARIABLE)

        hash.each do |column, value|
          previous_column_value = persistence_state[column]

          if persistence_state.has_key?(column) && previous_column_value != value
            changes[column] = value
          end
        end

        changes
      end

      def set_persistence_state(entity, raw)
        if !entity.is_a?(Integer) && !entity.is_a?(Symbol)
          entity.instance_variable_set(PERSISTENCE_STATE_VARIABLE, raw)
        end
      end

      def update_persistence_state(entity, raw)
        persistence_state = entity.instance_variable_get(PERSISTENCE_STATE_VARIABLE)

        if persistence_state
          persistence_state.merge!(raw)
        end
      end

      def set_entity_primary_key(entity, raw, key)
        if key && !primary_key.is_a?(Array)
          entity.instance_variable_set("@#{primary_key}", key)
          raw[primary_key] = key
        end
      end

      def prepare_key_condition_from_entity(entity)
        key_condition = {}

        if primary_key.is_a?(Array)
          primary_key.each do |key_part|
            key_part_value = entity.send(key_part)
            raise ArgumentError, "entity's primary key can't be nil, got nil for #{key_part}" unless key_part_value

            key_part_value = key_part_value.number if key_part_value.is_a?(ReeEnum::Value)
            key_condition[key_part] = key_part_value
          end
        elsif primary_key.is_a?(Symbol)
          key_value = entity.send(primary_key)
          raise ArgumentError, "entity's primary key can't be nil, got nil for #{primary_key}" unless key_value

          key_condition[primary_key] = key_value
        else
          raise StandardError, "primary key should be array or symbol"
        end

        key_condition
      end
    end
  end
end
