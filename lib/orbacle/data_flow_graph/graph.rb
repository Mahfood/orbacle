require 'rgl/adjacency'

module Orbacle
  module DataFlowGraph
    class Graph
      def initialize
        @graph = RGL::DirectedAdjacencyGraph.new
      end

      def add_vertex(node)
        @graph.add_vertex(node)
        node
      end

      def add_edges(nodes_source, nodes_target)
        Array(nodes_source).each do |source|
          Array(nodes_target).each do |target|
            @graph.add_edge(source, target)
          end
        end
      end

      def add_edge(x, y)
        @graph.add_edge(x, y)
      end

      def edges
        @graph.edges
      end

      def vertices
        @graph.vertices
      end

      def adjacent_vertices(v)
        @graph.adjacent_vertices(v)
      end

      def reverse
        @graph.reverse
      end

      def has_edge?(x, y)
        @graph.has_edge?(x, y)
      end
    end
  end
end
