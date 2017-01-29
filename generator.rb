class Generator

	def initialize(chain, level = 1, start = '__BEGIN__')
		@history   = [start]
		@max_level = level
		@chain     = chain
	end

	def statement(start = '__BEGIN__', mode = :random)
		
		if start == '__BEGIN__'
			current = start
			start   = ''
			history = []
		else
			history = start.split(' ')
			history.shift(history.length - @max_level) if history.length > @max_level
			current = history.join(' ')

		end

		next_word   = @chain[current].spawn(mode)
		output_text = start
		
		while !(next_word.empty? && history.empty?)

			if !next_word.empty?

				history << next_word
				history.shift if history.length > @max_level
				output_text += ' ' + next_word
			else
				history.shift
			end

			current   = history.join(' ')
			next_word = @chain[current].spawn(mode)
		end
		
		return output_text
	end
end