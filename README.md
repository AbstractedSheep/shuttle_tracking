The latest version of RPI's shuttle tracking web application.

## Installation

* Prerequisites: MySQL, Rails 3, ImageMagick, (on Debian/Ubuntu:) libjson-ruby
* Prerequisite Gems: MySQL, god, chronic_duration, RMagick
* Plugins Used: Attachable, AuthLogic

Installation:

* Fill in `config/database.yml` (an example is available: `config/database.yml.sample`)
* Run `bundle install` and `rake db:migrate`

Note: This project uses git submodules.  Run 'git submodule update --init' to download the submodules.

## Configuration

(note: all URLs are rails defaults)

* Point to your Central Authentication Server in `config/initializers/devise.rb`
* Setup your shuttle position updates.  An example is provided in `lib/tasks/sample.rake`
* Setup an administrative user.
* (optional) Add icons at `localhost:3000/icons`
* Add shuttles at `localhost:3000/vehicles`
* Add routes at `localhost:3000/routes`

### Setting up an Administrative User

* Start the server (see Usage).
* Login once through the web interface, at `localhost:3000/vehicles`
* Stop the server.
* Go to the project directory in a terminal.
* Run `rails c` to start the rails console.
* In the rails console:

```ruby
user = User.find_by_username("<your username>")
user.is_admin = true
user.save
exit
```

## Usage

* Starting the server: `rails server`
* Starting the service to retrieve shuttle updates: `rake tracking:auto_update`
