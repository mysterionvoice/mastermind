class ComputerPlayer
  def initialize
    @possible_codes = possible_codes
    @previous_guess = '1122'
  end

  def guess(guess_number, guess_clues)
    guess = guess_number == '1' ? @previous_guess : compute_new_guess(guess_clues)
    puts guess
    guess
  end

  private

  def possible_codes
    code_range = [1, 2, 3, 4, 5, 6]
    @possible_codes = code_range.repeated_permutation(4).to_a
  end

  def compute_new_guess(guess_clues)
    @possible_codes = @possible_codes.reject { |code| code.join('') == @previous_guess }
    reduce_possibles(guess_clues)

    score_hash = score_possibles

    guess_options = score_hash.select { |_key, value| value == score_hash.values.min(1).sum }
    @previous_guess = guess_options.keys[0].join('')
  end

  def reduce_possibles(guess_clues)
    previous_array = @previous_guess.split('')
    guess_clues.clues.each_with_index do |clue, i|
      case clue
      when 1
        @possible_codes = @possible_codes.select { |possible_code| possible_code[i] == previous_array[i].to_i }
      when 0
        @possible_codes = @possible_codes.select { |possible_code| possible_code.include? previous_array[i].to_i }
      end
    end
  end

  def score_possibles
    score_hash = Hash.new(0)
    @possible_codes.each do |guess|
      score_array = []

      @possible_codes.each { |possible_answer| score_array.push(assess_guess(guess, possible_answer)) }
      guess_hash = Hash.new(0)
      score_array.each { |num| guess_hash[num.to_s] += 1 }
      score_hash[guess] = guess_hash.max_by { |_key, value| value }[1]
    end

    score_hash
  end

  def assess_guess(guess_array, possible_answer)
    clue_array = []
    guess_array.each_with_index { |num, i| clue_array.push(get_clue(num, i, possible_answer)) }

    clue_array.sum
  end

  def get_clue(num, index, possible_answer)
    if num == possible_answer[index]
      1
    elsif possible_answer.any?(num)
      0
    else
      -1
    end
  end
end

# An addon to the String class to change the colour of the text
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def integer?
    /\A[-+]?\d+\z/.match?(self)
  end
end

# An item represented by one number within any given four digit code
class CodeItem
  attr_accessor :number, :color_code, :clue

  def initialize(number)
    @number = number
    @color_code = get_color_code(number)
  end

  private

  def get_color_code(number)
    color_codes = { '1' => 45, '2' => 46, '3' => 41, '4' => 44, '5' => 42, '6' => 43 }
    color_codes[number.to_s]
  end
end

# Stores the clues associated with a particular guess
class CodeClues
  attr_reader :clues

  def initialize
    @clues = []
  end

  def add_clue(state)
    @clues.push(state)
  end
end

# The class for displaying the gameboard
class GameBoard
  def draw_board(all_guesses, max_guesses, all_clues)
    draw_header
    puts '|====================================================|'

    draw_guesses(all_guesses, all_clues)

    draw_blank(max_guesses, all_guesses.length)

    puts '|====================================================|'
  end

  def display_code(code)
    code.each { |code_item| print "|#{"   #{code_item.number}   ".colorize(code_item.color_code).colorize(1)}" }
    print ''
  end

  private

  def display_clues(guess_clues)
    guess_clues.reduce('') do |clues_string, state|
      case state
      when 1
        clues_string + "\u2022".encode('UTF-8').colorize(31)
      when 0
        clues_string + "\u2022".encode('UTF-8')
      when -1
        clues_string
      end
    end
  end

  def draw_header
    puts '|====================================================|'
    puts '| Turn ||           Guesses             ||   Clues   |'
  end

  def draw_guesses(all_guesses, all_clues)
    all_guesses.each do |guess_number, guess|
      output_clues = display_clues(all_clues[guess_number].clues)
      add_on_spaces = spaces(all_clues, guess_number)
      print "|  #{guess_number}#{Integer(guess_number) < 10 ? ' ' : ''}  |"
      print display_code(guess)
      print "||   #{output_clues}#{add_on_spaces}    |"
      puts ''
      puts '|----------------------------------------------------|'
    end
  end

  def spaces(all_clues, guess_number)
    space = ''
    (4 - all_clues[guess_number].clues.reject { |item| item == -1 }.length).times { space += ' ' }
    space
  end

  def draw_blank(max_guesses, number_of_guesses)
    start_number = number_of_guesses + 1
    (max_guesses - number_of_guesses).times do
      puts "|  #{start_number}#{Integer(start_number) < 10 ? ' ' : ''}  ||       |       |       |       ||           |"
      puts '|----------------------------------------------------|'
      start_number += 1
    end
  end
end

# The class for creating a new game
class Game
  def initialize(game_mode)
    @guess_number = '1'
    @all_guesses = {}
    @all_clues = {}
    @max_guesses = 12
    @solved = false
    @gameboard = GameBoard.new
    @game_mode = game_mode
    @game_mode == '1' ? start_breaker : start_maker
  end

  private

  def start_breaker
    generate_code

    puts "When prompted, enter your first code guess by typing in four digits representing the different colours.\n"\
    "For example 1234, then press enter to log your guess and get the clues returned to you.\n"\
    "\n"
    puts 'The secret code has been set, you now have 12 attempts to break the code, good luck!'

    request_guess until @solved || Integer(@guess_number) == (@max_guesses + 1)

    breaker_solved

    next_action
  end

  def breaker_solved
    if @solved
      puts('Congratulations, you won the game!!')
    else
      puts("Sorry, you\'re out of turns, the correct code was #{@secret_string}.\n"\
      ' Better luck next time!!')
    end
  end

  def start_maker
    puts 'Please set the secret code:'
    @secret_string = gets.chomp
    @secret_code = codify(@secret_string)

    if valid_code?(@secret_string)
      engage_computer_player
    else
      puts 'That secret code is not valid, please try again'
      start_maker
    end
  end

  def engage_computer_player
    @computer = ComputerPlayer.new
    @secret_array = @secret_string.split('')
    request_guess until @solved || Integer(@guess_number) == (@max_guesses + 1)

    @solved ? puts('The computer broke your code, hard luck!') : puts('Congratulations, your code beat the computer!')
    next_action
  end

  def generate_code
    @secret_code = []
    4.times do
      code_item = CodeItem.new(rand(1..6))
      @secret_code.push(code_item)
    end

    @secret_string = @secret_code.reduce('') { |str, item| str + item.number.to_s }
    @secret_array = @secret_string.split('')
  end

  def codify(guess)
    guess_codes = []
    guess.split('').each { |number| guess_codes.push(CodeItem.new(Integer(number))) }
    guess_codes
  end

  def request_guess
    puts "\nPlease enter guess number #{@guess_number}:"
    guess = @game_mode == '1' ? gets.chomp : @computer.guess(@guess_number, @all_clues[(@guess_number.to_i - 1).to_s])
    puts ''

    if valid_code?(guess)
      log_guess(guess)
    else
      puts 'That guess is not valid, please try again'
      request_guess
    end

    @gameboard.draw_board(@all_guesses, @max_guesses, @all_clues)
  end

  def valid_code?(code)
    code_array = code.split('')

    return unless code_array.length == 4

    code_array.all? { |num| num.integer? && Integer(num) >= 1 && Integer(num) <= 6 }
  end

  def log_guess(guess)
    @all_guesses[@guess_number] = codify(guess)
    @all_clues[@guess_number] = analyse_guess(guess.split(''), CodeClues.new)

    @guess_number = (@guess_number.to_i + 1).to_s
    @solved = guess == @secret_string
  end

  def analyse_guess(guess_array, guess_clues)
    guess_array.each_with_index do |num, i|
      if num == @secret_array[i]
        guess_clues.add_clue(1)
      elsif @secret_array.any?(num)
        guess_clues.add_clue(0)
      else
        guess_clues.add_clue(-1)
      end
    end

    guess_clues
  end
end

def next_action
  puts 'Would you like to play again? Enter \'y\' for yes or \'n\' for no'

  case gets.chomp.downcase
  when 'y', 'yes'
    request_restart
  when 'n', 'no'
    puts 'Ok, see you next time!'
  else
    puts 'Sorry, I didn\'t quite catch that!'
    next_action
  end
end

def request_restart
  puts "Please enter \'1\' if would like to be the code breaker of \'2\' if you would like to be the\n"\
  'code maker'

  game_mode = gets.chomp
  puts ' '

  Game.new(game_mode)
end

puts "\n"\
"                         *** #{'Welcome to Mastermind!'.colorize(4)} ***               \n"\
" \n"\
"Mastermind is a code-breaking game for two players. In this case, you and the computer.\n"\
" \n"\
"You will have the choice to be the code maker or the code breaker. As the code maker, you\n"\
"will define the code that the computer will then attempt to break.  As the code breaker,\n"\
"the computer will set the code, which you then have to break. The code breaker is required\n"\
"to complete the task within 12 attempts!\n"\
" \n"\
"After each attempt, the code breaker is given clues as follows:\n"\
"#{"\u2022".encode('UTF-8').colorize(31)} - Indicates that the correct colour is selected"\
" and that it is in the right spot.\n"\
"#{"\u2022".encode('UTF-8')} - Indicates that the correct colour is selected but that colour"\
" is in the wrong location.\n"\
" \n"\
"Please enter \'1\' if would like to be the code breaker of \'2\' if you would like to be the\n"\
'code maker'

game_mode = gets.chomp
puts ' '

Game.new(game_mode)