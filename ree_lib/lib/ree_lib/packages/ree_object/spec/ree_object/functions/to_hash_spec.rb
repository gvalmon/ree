# frozen_string_literal = true

RSpec.describe :to_hash do
  link :to_hash, from: :ree_object

  context "object" do
    let(:klass) {
      Class.new do
        attr_reader :integer, :string, :array, :hash, :object

        def initialize
          @integer = 1
          @string = 'string'
          @array = [1, 'string', 3, { 'name' => 'John'}]
          @hash = { id: 1, 'test' => 2, nested: { some_value: 1, another_value: 2 } }
          @object = Object.new
          @klass = Object
          @module = Module
          @object.instance_exec do
            @name = 'John'
            @last_name = 'Doe'
          end
        end 
      end
    }

    context "Struct" do
      it {
        klass = Struct.new(:id, :name)
        result = to_hash(klass.new(1, 'John'))

        expect(result).to eq({id: 1, name: 'John'})
      }  
    end

    context "OpenStruct" do
      it {
        require 'ostruct'
        obj = OpenStruct.new(id: 1, name: 'John')
        result = to_hash(obj)

        expect(result).to eq({id: 1, name: 'John'})
      }
    end

    context "basic types" do
      it {
        obj = Date.new
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = Time.new
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = 1
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = "string"
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = true
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = false
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = nil
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = :symbol
        result = to_hash(obj)
        expect(result).to eq(obj)
      }

      it {
        obj = Object.new
        result = to_hash(obj)
        expect(result).to eq({})
      }
    end

    context "without options" do
      it {
        result = to_hash(klass.new)
  
        expected = {
          integer: 1,
          string: 'string',
          array: [1, 'string', 3, { name: 'John'}],
          hash: { id: 1, test: 2, nested: { some_value: 1, another_value: 2 } },
          klass: Object,
          module: Module,
          object: {
            name: 'John',
            last_name: 'Doe'
          }
        }
  
        expect(result).to eq(expected)
      }
    end

    context "with options" do
      context "same include and exclude options" do
        it {
          expect {
            to_hash(
              klass.new,
              include: [:integer, :object, hash: [:id, :missing]],
              exclude: [:integer, hash: [:id]]
            )
          }.to raise_error(ArgumentError, /Exclude and include have same values: /)
        }
      end

      context "include and exclude options" do
        it {
          expect {
            to_hash(
              klass.new,
              include: [:integer, :string, object: [:name, :last_name]],
              exclude: [:object, :hash]
            )
          }.to raise_error(ArgumentError)
        }
      end

      context "include, skip missing keys and string output keys options" do
        it {
          result = to_hash(
            klass.new,
            include: [
              :integer,
              object: [:name],
              hash: [:id, :missing, nested: [:some_value]]
            ],
            output_keys: :string,
            missing: :skip
          )
    
          expected = {
            'integer' => 1,
            'hash' => { 'id' => 1, 'nested' => { 'some_value' => 1 } },
            'object' => {
              'name' => 'John'
            }
          }
    
          expect(result).to eq(expected)
        }
      end

  
      context "exclude and symbol output keys options" do
        it {
          result = to_hash(
            klass.new,
            exclude: [:string, :array, hash: [:nested], object: [:name]],
            output_keys: :symbol
          )
    
          expected = {
            integer: 1,
            klass: Object,
            module: Module,
            object: {
              last_name: 'Doe'
            },
            hash: {
              id: 1,
              test: 2
            }
          }
    
          expect(result).to eq(expected)
        }
      end
  
      context "include, missing keys as nil and symbol output keys options" do
        it {
          result = to_hash(
            klass.new,
            include: [object: [:name, :surname]],
            output_keys: :symbol,
            missing: :nil
          )
    
          expected = {
            object: {
              name: 'John',
              surname: nil
            }
          }
    
          expect(result).to eq(expected)
        }
      end
  
      context "raise error on missing keys option" do
        it {
          expect {
            to_hash(
              klass.new,
              include: [object: [:name, :surname]],
              output_keys: :symbol,
              missing: :raise
            )
          }.to raise_error(ReeObject::ToHash::MissingIncludeKeyErr, /Missing key /)
        }
      end
  

      context "check for recursion" do
        let(:obj_klass) {
          Class.new do
            def set(v)
              @value = v
            end
          end
        }
    
        it {
          obj = obj_klass.new
          obj.set([obj])
    
          expect {
            to_hash(obj)
          }.to raise_error(ReeObject::ToHash::RecursiveObjectErr, /Recursive object found: /)
        }
      end
    end
  end
end