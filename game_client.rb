require 'gosu'
require 'thread'
require 'faye/websocket'
require 'eventmachine'
require 'json'

class Tutorial < Gosu::Window
  def initialize
    @coop_width = 640
    @coop_height = 480
    @num_x_cells = 16
    @num_y_cells = 12
    super @coop_width, @coop_height
    self.caption = "Tutorial Game"
    @font = Gosu::Font.new(20)
    @network = Network.new
    @derp = "a string"
    @cell_width = @coop_width/@num_x_cells
    @cell_height = @coop_height/@num_y_cells

    @chickens = Array.new
  end

  def update
    super
    @network.dispatch_network_events_to(self)
    self.caption = "stuff"
  end

  def draw
    @font.draw(@derp,5, 5, 1, 1.0, 1.0, Gosu::Color::YELLOW)
    @chickens.each do |chicken|
      chicken.draw(@cell_width,@cell_height)
    end
  end

  def on_derp(herp)
    @derp = herp
    message = JSON.parse(herp)
    @chickens = []
    message["chickens"].each do |chicken|
      @chickens.push( Chicken.new(chicken) )
    end
  end

  class Chicken
    def initialize(chicken)
      @image = Gosu::Image.new( "public/chicken.png" )
      @x = chicken[1]["x"]
      @y = chicken[1]["y"]
      @name = chicken[0]
      @font = Gosu::Font.new(19)
    end

    def warp(x,y)
      @x, @y = x, y
    end

    def draw(cell_width,cell_height)
      @image.draw(@x*cell_width,@y*cell_height,2)
      @font.draw(@name,@x*cell_width,(@y+0.8)*cell_height,3,1.0,1.0,Gosu::Color::GREEN)
    end
  end


  class Network
    def initialize
      @network_event_queue = Queue.new
      @thread = Thread.new do
        EM.run {
          ws = Faye::WebSocket::Client.new('wss://hat.chti.me/game')

          ws.on :open do |event|
            p [:open]
            ws.send('Hello, world!')
          end

          ws.on :message do |event|
            p [:message, event.data]
            push_event(:on_derp, event.data)
          end

          ws.on :close do |event|
            p [:close, event.code, event.reason]
            ws = nil
          end
        }
      end
    end

    def dispatch_network_events_to(receiver)
      @network_event_queue.size.times do
        @network_event_queue.pop.call(receiver)
      end
    end

    def push_event(symbol, *args)
      @network_event_queue.push(proc { |receiver| receiver.send(symbol, *args) })
    end
  end
end
Tutorial.new.show
