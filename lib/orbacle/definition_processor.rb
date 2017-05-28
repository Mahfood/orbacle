require 'parser/current'

class Orbacle::DefinitionProcessor < Parser::AST::Processor
  def process_file(file, line, character)
    ast = Parser::CurrentRuby.parse(file)

    @searched_line = line
    @searched_character = character
    # reset_file!

    process(ast)

    return @found_constant
    # return {
    #   methods: @methods,
    #   constants: @constants,
    # }
  end

  # ast.children[2].children[1].children[2].children[0].children[2].children[5].children[1].children[0]
  def on_const(ast)
    # puts "Processing const '#{ast.inspect}'"
    name_loc_range = ast.loc.name
    if @searched_line == name_loc_range.line && name_loc_range.column_range.include?(@searched_character)
      # puts "FOUND #{name_loc_range.inspect}"
      @found_constant = ast.children[1].to_s
    end
  end

  # def on_module(ast)
  #   ast_name, _ = ast.children
  #   prename, module_name = get_nesting(ast_name)

  #   @constants << [
  #     scope_from_nesting_and_prename(@current_nesting, prename),
  #     module_name,
  #     :mod,
  #     { line: ast_name.loc.line },
  #   ]

  #   current_nesting_element = [:mod, prename, module_name]
  #   @current_nesting << current_nesting_element

  #   super(ast)

  #   @current_nesting.pop
  # end

  # def on_class(ast)
  #   ast_name, _ = ast.children
  #   prename, klass_name = get_nesting(ast_name)

  #   @constants << [
  #     scope_from_nesting_and_prename(@current_nesting, prename),
  #     klass_name,
  #     :klass,
  #     { line: ast_name.loc.line },
  #   ]

  #   current_nesting_element = [:klass, prename, klass_name]
  #   @current_nesting << current_nesting_element

  #   super(ast)

  #   @current_nesting.pop
  # end

  # def on_def(ast)
  #   method_name, _ = ast.children

  #   @methods << [ nesting_to_scope(@current_nesting), method_name.to_s ]

  #   super(ast)
  # end

  # def on_casgn(ast)
  #   const_prename, const_name, _ = ast.children

  #   @constants << [
  #     scope_from_nesting_and_prename(@current_nesting, prename(const_prename)),
  #     const_name.to_s,
  #     :other,
  #     { line: ast.loc.line }
  #   ]

  #   super(ast)
  # end

  # private

  # def reset_file!
  #   @current_nesting = []
  #   @methods = []
  #   @constants = []
  # end

  # def nesting_to_scope(nesting)
  #   return nil if nesting.empty?

  #   nesting.map do |_type, pre, name|
  #     pre + [name]
  #   end.flatten.join("::")
  # end

  # def prename(ast_const)
  #   if ast_const.nil?
  #     []
  #   else
  #     prename(ast_const.children[0]) + [ast_const.children[1].to_s]
  #   end
  # end

  # def get_nesting(ast_const)
  #   [prename(ast_const.children[0]), ast_const.children[1].to_s]
  # end

  # def scope_from_nesting_and_prename(nesting, prename)
  #   scope_from_nesting = nesting_to_scope(nesting)

  #   result = ([scope_from_nesting] + prename).compact.join("::")
  #   result.empty? ? nil : result
  # end
end
