The latest version of RPI's shuttle tracking web application.

***

## Installation

* Prerequisites: MySQL, Rails 3, ImageMagick
* Prerequisite Gems: MySQL, god, chronic_duration, RMagick
* Plugins Used: Attachable, AuthLogic

Installation:
`bundle install`
Fill-in `database.yml` (an example, `database.yml.sample`, is provided)
`rake db:migrate`

Note: Some people have trouble with Attachable.  Try reinstalling as a workaround:
(with Rails 3)
`rails plugin install https://github.com/bamnet/attachable.git --force`

***

## Configuration

(note: all URLs are rails defaults)
* Point to your Central Authentication Server in `config/initializers/devise.rb`
* Setup your shuttle position updates.  An example is provided in `lib/tasks/sample.rake`
* Setup an administrative user.
* (optional) Add icons at `localhost:3000/icons`
* Add shuttles at `localhost:3000/vehicles`
* Add routes at `localhost:3000/routes`

### Setting up and Administrative User

* Start the server (see Usage).
* Login once through the web interface, at `localhost:3000/vehicles`
* Stop the server.
* Go to the project directory in a terminal.
* Run `rails c` to start the rails console.
* In the rails console:
	user = User.find_by_username("<your username>")
	user.is_admin = true
	user.save
	exit

## Usage:

* Starting the server: `rails server`
* Starting the service to retrieve shuttle updates: `rake tracking:auto_update`
