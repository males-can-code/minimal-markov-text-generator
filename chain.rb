require "json"

module Treat
	config_file = File.open('./config.json', 'r')
	Config = JSON.load(config_file)
	Config["delimiters"] = ["(",")",",",",",":","'",";"]
	Config["unwanted_chars"] = ["\n", "-"]

	def Treat.treat(text)
		unwanted_chars = Config['unwanted_chars']
		text = text.gsub(/[#{unwanted_chars.join}]{1}/,' ')

		return text
	end

	def Treat.extract(text)

		text = treat(text)

		delimiters = Config['delimiters']
		delim_regex = /(?<!\w)[#{delimiters.join}]{1}|[#{delimiters.join}](?=\W)/

		statement_list = []

		while delim_regex.match(text)
			statement_list << $`
			text = $'
			prepend = $'
		end

		if prepend
			statement_list << prepend
		else
			statement_list << text
		end

		statement_list = statement_list.keep_if { |statement|
			/\w/ =~ statement 
		}

		return statement_list
	end
end

class Suffix < Hash

	def initialize
		super 0
		@num_of_words = 0
	end

	def <<(word)
		self[word]    += 1
		@num_of_words += 1
	end

	def spawn(select = :random)
		case (select)

		when :max then
			max_val = self.values.max()

			self.each_key { |word|
				if self[word] == max_val
					return word
				end
			}

		when :random then
			random_float = Random.rand
			current      = 0.0
			accumulated  = 0.0

			self.each_key { |word|
				num_of_times  = self[word].to_f
				accumulated  += num_of_times/@num_of_words

				if (current ... accumulated).include?(random_float)
					return word
				end

				current = accumulated
			}
		end
	end

	def set_num_of_words()

		total = 0
		self.values.each { |x| total += x }
		@num_of_words = total
	end
end

class Chain < Hash

	def initialize()
		super {|hash,key| hash[key]=Suffix.new}
	end

	def Chain.build(text,level = 1)
		statement_list = Treat.extract(text)
		chain          = Chain.new

		count = 1

		while count <= level
			statement_list.each { |statement|
				words = statement.split(' ')
				chain["__BEGIN__"] << words[0]
				words[0...-count].each_index do |index|
					prefix = words[index,count].join(' ')
					chain[prefix] << words[index+count]
				end
			}
			count+=1
		end
		return chain
	end

	def Chain.load(file_name)
		File.open(file_name) { |file|
			text = file.read()
			hash = JSON.parse(text)

			chain = Chain.new

			hash.each_key { |key|
				suffix = Suffix.new
				s_hash = hash[key]

				s_hash.each_key { |s_key|
					suffix[s_key] = s_hash[s_key]
				}
				
				suffix.set_num_of_words()
				chain[key] = suffix
			}

			return chain
		}
	end
end