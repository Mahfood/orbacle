require 'spec_helper'

module Orbacle
  RSpec.describe DataFlowGraph do
    specify "simple method in class declaration" do
      file = <<-END
      class Foo
        def bar
        end
      end
      END

      result = compute_graph(file)

      meth = find_method(result, "Foo", "bar")
      expect(meth.visibility).to eq(:public)
      expect(meth.line).to eq(2)

      klass = find_constant(result, "", "Foo")
      expect(klass.line).to eq(1)
      expect(klass.inheritance_name).to eq(nil)
      expect(klass.inheritance_nesting).to eq([])
    end

    specify "private method in class declaration" do
      file = <<-END
      class Foo
        private
        def bar
        end
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "Foo", "bar")
      expect(meth.visibility).to eq(:private)
      expect(meth.line).to eq(3)
    end

    specify "rechanging visibility of methods in class declaration" do
      file = <<-END
      class Foo
        private
        public
        def bar
        end
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "Foo", "bar")
      expect(meth.visibility).to eq(:public)
    end

    specify "changing visibility to protected" do
      file = <<-END
      class Foo
        protected
        def bar
        end
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "Foo", "bar")
      expect(meth.visibility).to eq(:protected)
    end

    specify "private keyword does not work if not used inside object declaration" do
      file = <<-END
      private
      def bar
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "", "bar")
      expect(meth.visibility).to eq(:public)
    end

    specify "using private with passing a symbol" do
      file = <<-END
      class Foo
        def bar
        end
        private :bar
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "Foo", "bar")
      expect(meth.visibility).to eq(:private)
    end

    specify "using private with passing a symbol does not change visibility of future methods" do
      file = <<-END
      class Foo
        def bar
        end
        private :bar
        def baz
        end
      end
      END

      result = compute_graph(file)
      meth = find_method(result, "Foo", "baz")
      expect(meth.visibility).to eq(:public)
    end

    specify do
      file = <<-END
      class Foo
        def bar
        end

        def baz
        end
      end
      END

      result = compute_graph(file)

      meth = find_method(result, "Foo", "bar")
      expect(meth.line).to eq(2)

      meth = find_method(result, "Foo", "baz")
      expect(meth.line).to eq(5)
    end

    it do
      file = <<-END
      module Some
        class Foo
          def bar
          end

          def baz
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo", "bar", { line: 3 }],
        ["Some::Foo", "baz", { line: 6 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(name: "Some"),
        build_klass(scope: "Some", name: "Foo", nesting: ["Some"]),
      ])
    end

    it do
      file = <<-END
      module Some
        class Foo
          def oof
          end
        end

        class Bar
          def rab
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo", "oof", { line: 3 }],
        ["Some::Bar", "rab", { line: 8 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(name: "Some"),
        build_klass(scope: "Some", name: "Foo", nesting: ["Some"]),
        build_klass(scope: "Some", name: "Bar", nesting: ["Some"]),
      ])
    end

    it do
      file = <<-END
      module Some
        module Foo
          class Bar
            def baz
            end
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo::Bar", "baz", { line: 4 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(name: "Some"),
        build_module(scope: "Some", name: "Foo"),
        build_klass(scope: "Some::Foo", name: "Bar", nesting: ["Some", "Foo"]),
      ])
    end

    it do
      file = <<-END
      module Some::Foo
        class Bar
          def baz
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo::Bar", "baz", { line: 3 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(scope: "Some", name: "Foo"),
        build_klass(scope: "Some::Foo", name: "Bar", nesting: ["Some::Foo"]),
      ])
    end

    it do
      file = <<-END
      module Some::Foo::Bar
        class Baz
          def xxx
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo::Bar::Baz", "xxx", { line: 3 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(scope: "Some::Foo", name: "Bar"),
        build_klass(scope: "Some::Foo::Bar", name: "Baz", nesting: ["Some::Foo::Bar"]),
      ])
    end

    it do
      file = <<-END
      module Some::Foo
        class Bar::Baz
          def xxx
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo::Bar::Baz", "xxx", { line: 3 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(scope: "Some", name: "Foo"),
        build_klass(scope: "Some::Foo::Bar", name: "Baz", nesting: ["Some::Foo"])
      ])
    end

    it do
      file = <<-END
      class Bar
        class ::Foo
          def xxx
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Foo", "xxx", { line: 3 }],
      ])
      expect(r[:constants]).to match_array([
        build_klass(name: "Bar"),
        build_klass(name: "Foo", nesting: ["Bar"])
      ])
    end

    it do
      file = <<-END
      class Bar
        module ::Foo
          def xxx
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Foo", "xxx", { line: 3 }],
      ])
      expect(r[:constants]).to match_array([
        build_klass(name: "Bar"),
        build_module(name: "Foo"),
      ])
    end

    it do
      file = <<-END
      def xxx
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["", "xxx", { line: 1 }],
      ])
      expect(r[:constants]).to be_empty
    end

    specify do
      file = <<-END
      class Foo
        Bar = 32

        def bar
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Foo", "bar", { line: 4 }],
      ])
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo"),
        build_constant(name: "Bar", scope: "Foo")
      ])
    end

    specify do
      file = <<-END
      class Foo
        Ban::Baz::Bar = 32
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([])
      expect(r[:constants]).to match_array([
        build_constant(name: "Bar", scope: "Foo::Ban::Baz"),
        build_klass(name: "Foo"),
      ])
    end

    specify do
      file = <<-END
      class Foo
        ::Bar = 32
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_constant(name: "Bar"),
        build_klass(name: "Foo"),
      ])
    end

    specify do
      file = <<-END
      class Foo
        ::Baz::Bar = 32
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_constant(name: "Bar", scope: "Baz"),
        build_klass(name: "Foo"),
      ])
    end

    specify do
      file = <<-END
      class Foo
        ::Baz::Bam::Bar = 32
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_constant(name: "Bar", scope: "Baz::Bam"),
        build_klass(name: "Foo"),
      ])
    end

    it do
      file = <<-END
      module Some
        module Foo
          def oof
          end
        end

        module Bar
          def rab
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Some::Foo", "oof", { line: 3 }],
        ["Some::Bar", "rab", { line: 8 }],
      ])
      expect(r[:constants]).to match_array([
        build_module(name: "Some"),
        build_module(scope: "Some", name: "Foo"),
        build_module(scope: "Some", name: "Bar"),
      ])
    end

    it "method in method definition" do
      file = <<-END
      class Foo
        def bar
          def baz
          end
        end
      end
      END

      result = compute_graph(file)

      meth = find_method(result, "Foo", "baz")
      expect(meth.line).to eq(3)
    end

    specify do
      file = <<-END
      class Foo < Bar
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo", inheritance: "Bar")
      ])
    end

    specify do
      file = <<-END
      class Foo < Bar::Baz
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo", inheritance: "Bar::Baz")
      ])
    end

    specify do
      file = <<-END
      class Foo < ::Bar::Baz
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo", inheritance: "::Bar::Baz")
      ])
    end

    specify do
      file = <<-END
      module Some
        class Foo < Bar
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_module(name: "Some"),
        build_klass(scope: "Some", name: "Foo", inheritance: "Bar", nesting: ["Some"]),
      ])
    end

    specify do
      file = <<-END
      Foo = Class.new(Bar)
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo", inheritance: "Bar")
      ])
    end

    specify do
      file = <<-END
      Foo = Class.new
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_klass(name: "Foo")
      ])
    end

    specify do
      file = <<-END
      Foo = Module.new
      END

      r = parse_file_methods.(file)
      expect(r[:constants]).to match_array([
        build_module(name: "Foo")
      ])
    end

    specify do
      file = <<-END
      class Foo
        def self.bar
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Metaklass(Foo)", "bar", { line: 2 }],
      ])
    end

    specify do
      file = <<-END
      class Foo
        class << self
          def foo
          end
        end
      end
      END

      r = parse_file_methods.(file)
      expect(r[:methods]).to eq([
        ["Metaklass(Foo)", "foo", { line: 3 }],
      ])
    end

    # Currently does not work
    context "misbehaviours" do
      specify "using private with passing a method definition" do
        file = <<-END
        class Foo
          private def bar
          end
        end
        END

        result = compute_graph(file)
        meth = find_method(result, "Foo", "bar")
        expect(meth.visibility).to eq(:public)
        # expect(meth.visibility).to eq(:private)
      end

      specify "using private with passing something else than literals" do
        file = <<-END
        class Foo
          def bar
          end

          x = "bar"
          private x
        end
        END

        result = compute_graph(file)
        meth = find_method(result, "Foo", "bar")
        expect(meth.visibility).to eq(:public)
        # expect(meth.visibility).to eq(:private)
      end

      it "method in method definition with changed visibility" do
        file = <<-END
        class Foo
          private
          def bar
            def baz
            end
          end
        end
        END

        result = compute_graph(file)

        meth = find_method(result, "Foo", "baz")
        expect(meth.visibility).to eq(:private)
        # expect(meth.visibility).to eq(:public)
      end
    end

    def parse_file_methods
      ->(file) {
        service = DataFlowGraph.new
        result = service.process_file(file)
        {
          methods: result.tree.methods.map {|m| [m.scope.to_s, m.name, { line: m.line }] },
          constants: result.tree.constants.map do |c|
            if c.is_a?(GlobalTree::Klass)
              [c.class, c.scope.absolute_str, c.name, c.inheritance_name, c.inheritance_nesting]
            else
              [c.class, c.scope.absolute_str, c.name]
            end
          end
        }
      }
    end

    def compute_graph(file)
      service = DataFlowGraph.new
      service.process_file(file)
    end

    def find_methods(result, scope, name)
      result.tree.methods.select {|m| m.name == name && m.scope.to_s == scope }
    end

    def find_method(result, scope, name)
      find_methods(result, scope, name).first
    end

    def find_constants(result, scope, name)
      result.tree.constants.select {|c| c.name == name && c.scope.to_s == scope }
    end

    def find_constant(result, scope, name)
      find_constants(result, scope, name).first
    end

    def build_klass(scope: "", name:, inheritance: nil, nesting: [])
      [GlobalTree::Klass, scope, name, inheritance, nesting]
    end

    def build_module(scope: "", name:)
      [GlobalTree::Mod, scope, name]
    end

    def build_constant(scope: "", name:)
      [GlobalTree::Constant, scope, name]
    end
  end
end