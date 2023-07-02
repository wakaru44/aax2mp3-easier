.PHONY: help init get-aax encode

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.secrets/audible_pass:
	@echo "Enter your audible password"
	@read -s pass; echo $$pass > .secrets/audible_pass
	@echo "Enter your audible username"
	@read user; echo $$user > .secrets/audible_user

.secrets/activation_bytes: ## Generate the activations bytes
	# get the activation bytes with the audible CLI, installed via pip
	pip install audible-cli
	env/bin/audible quickstart
	env/bin/audible activation_bytes 
	@echo "Copy that string to  `.secrets/activation_bytes`"


audible-activator-master: ## Download audible-activator
# run aax2mp3_easy.sh with fake email and password redirecting stderr and stdout to null and ignore failure
	@./aax2mp3_easy.sh fake@email.com noPassword nonexistantFile 2>&1 >/dev/null \
		|| (echo "Downloading audible-activator" )
	
init: audible-activator-master .secrets/audible_pass ## Initialize the project
	@echo "Initializing project"
	@mkdir -p ./source_books
	@mkdir -p ./output_books
	brew bundle install

get-aax: ## Copy your aax files from your MacOS ~/Downloads folder
	mkdir -p ./source_books
	mv ~/Downloads/*aax  ./source_books

old-encode: .secrets/audible_pass ## Start encoding files with the big do-it-all script
	## ./aax2mp3_easy.sh $(shell cat .secrets/audible_user) $(shell cat .secrets/audible_pass ) ${files}
	@$(foreach file, $(shell ls ./source_books), ./aax2mp3_easy.sh $(shell cat .secrets/audible_user) $(shell cat .secrets/audible_pass ) ./source_books/$(file);)

encode: .secrets/activation_bytes ## Start encoding using just the minimal tool
	bash AAXtoMP3-master/AAXtoMP3 -A $(shell cat .secrets/activation_bytes) --target_dir ./output_books source_books/*.aax

process: get-aax ## Process the files in order. needs an initialised project
	bin/process.sh > process_$(shell date +%F:%H:%M  ).log 2>&1
