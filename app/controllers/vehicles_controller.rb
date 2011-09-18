class VehiclesController < ApplicationController
  authorize_resource :except => [:current]

  # GET /vehicles
  # GET /vehicles.xml
  def index
    @vehicles = Vehicle.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vehicles }
    end
  end

  # GET /vehicles/current.kml
  # GET /vehicles/current.js
  def current
    @vehicles = Vehicle.active

    respond_to do |format|
      format.js { render :json => @vehicles.to_json(
        :only => [:id, :name],
        :include => {
          :latest_position => {
            :only => [:latitude, :longitude, :speed, :heading, :timestamp],
            :methods => [:public_status_msg, :cardinal_point]
          },
          :icon => {
            :only => [:id]
          }
         }
      ) }
      format.kml
    end
  end

  # GET /vehicles/1
  # GET /vehicles/1.xml
  def show
    @vehicle = Vehicle.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @vehicle }
    end
  end

  # GET /vehicles/new
  # GET /vehicles/new.xml
  def new
    @vehicle = Vehicle.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @vehicle }
    end
  end

  # GET /vehicles/1/edit
  def edit
    @vehicle = Vehicle.find(params[:id])
  end

  # POST /vehicles
  # POST /vehicles.xml
  def create
    @vehicle = Vehicle.new(params[:vehicle])

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to(@vehicle, :notice => 'Vehicle was successfully created.') }
        format.xml  { render :xml => @vehicle, :status => :created, :location => @vehicle }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @vehicle.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /vehicles/1
  # PUT /vehicles/1.xml
  def update
    @vehicle = Vehicle.find(params[:id])

    respond_to do |format|
      if @vehicle.update_attributes(params[:vehicle])
        format.html { redirect_to(@vehicle, :notice => 'Vehicle was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @vehicle.errors, :status => :unprocessable_entity }
      end
    end
  end

  def pull_update
    require "net/http"
    require "uri"
    require "json"

    url = URI.parse("http://shuttles.rpi.edu/vehicles/current.js")
    result = Net::HTTP.get(url)
    
    @jsonVehicles = result.body.from_json

    for newVehicle in @jsonVehicles
      foundVehicle = Vehicle.find(newVehicle.identifier)
      #TODO: do something
    end

  end

  # DELETE /vehicles/1
  # DELETE /vehicles/1.xml
  def destroy
    @vehicle = Vehicle.find(params[:id])
    @vehicle.destroy

    respond_to do |format|
      format.html { redirect_to(vehicles_url) }
      format.xml  { head :ok }
    end
  end
end
