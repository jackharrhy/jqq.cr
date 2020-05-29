require "ncurses"

KEY_BACKSPACE = 127
KEY_ESCAPE    =  27

def jq(expr, file)
  process = Process.new("jq", [expr, file], output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)

  output = process.output.gets_to_end
  error = process.error.gets_to_end

  status = process.wait

  {
    :output    => output,
    :error     => error,
    :exit_code => status.exit_code,
  }
end

def print_expr(expr_win, expr, expr_pos)
  expr_win.clear
  expr_win.print(expr)
  expr_win.set_pos(0, expr_pos)
  expr_win.refresh
end

def print_jq(view_win, expr, filename)
  jq_result = jq(expr, filename)

  view_win.clear
  view_win.print jq_result[:output].to_s
  view_win.refresh
end

def app(filename, initial_expr)
  NCurses.start
  NCurses.cbreak
  NCurses.no_echo

  title_win = NCurses::Window.new(
    height: 1,
    width: NCurses.width,
    x: 0,
    y: 0
  )

  title_win.print "jqq.cr: #{filename}"
  title_win.refresh

  expr_win = NCurses::Window.new(
    height: 1,
    width: NCurses.width,
    x: 0,
    y: 1
  )

  expr = initial_expr
  expr_pos = expr.size

  view_win = NCurses::Window.new(
    height: NCurses.height - 2,
    width: NCurses.width,
    x: 0,
    y: 2
  )

  print_jq(view_win, expr, filename)
  print_expr(expr_win, expr, expr_pos)

  expr_win.get_char do |ch|
    case ch
    when KEY_ESCAPE
      break
    when KEY_BACKSPACE
      if expr_pos > 0
        expr = expr[0...(expr_pos - 1)] + expr[expr_pos..-1]
        expr_pos -= 1
      end
    when .is_a? Char
      expr = expr[0...expr_pos] + ch + expr[expr_pos..-1]
      expr_pos += 1
    else
    end

    print_jq(view_win, expr, filename)
    print_expr(expr_win, expr, expr_pos)
  end

  NCurses.end
end

example_filename = ARGV[1]
initial_expr = ARGV[0]

app(example_filename, initial_expr)
