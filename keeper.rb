#! /usr/bin/env ruby -w

require 'rubygems'

require 'httparty'
require 'json'

require 'awesome_print'
require 'net-http-spy'

class Soldier

  def initialize key, data = {}
    @key, @data = key, data
  end

  def id
    key
  end

  def name
    data['name']
  end

  def tag
    data['tag']
  end

  def rank
    data['rank']
  end

  def score
    data['score']
  end

  def kills
    data['kills']
  end

  def deaths
    data['deaths']
  end

  def squad
    data['squad']
  end

  def commander?
    data['role'] == 2
  end

  def role
    data['role']
  end

  def to_s
    return name if tag.empty?
    "[#{tag}] #{name}"
  end

  private

  def key
    @key
  end

  def data
    @data
  end

end

class BattlefieldMap

  ##
  # From Keeper JSON:
  #   "currentMap": "XP4/Levels/XP4_SubBase/XP4_SubBase"
  #
  def initialize current_map
    @current_map = current_map
  end

  def name
    BATTLEFIELD_4_MAPS.fetch( map_key, 'Unknown')
  end

  private

  def current_map
    @current_map
  end

  def map_key
    current_map.split('/').last
  end

  BATTLEFIELD_4_MAPS = {
    "MP_Abandoned"  => "Zavod 311",
    "MP_Damage"     => "Lancang Dam",
    "MP_Flooded"    => "Flood Zone",
    "MP_Journey"    => "Golmud Railway",
    "MP_Naval"      => "Paracel Storm",
    "MP_Prison"     => "Operation Locker",
    "MP_Resort"     => "Hainan Resort",
    "MP_Siege"      => "Siege Of Shanghai",
    "MP_TheDish"    => "Rogue Transmission",
    "MP_Tremors"    => "Dawnbreaker",
    "XP0_Caspian"   => "Caspian Border 2014",
    "XP0_Firestorm" => "Operation Firestorm 2014",
    "XP0_Metro"     => "Operation Metro 2014",
    "XP0_Oman"      => "Gulf Of Oman 2014",
    "XP1_001"       => "Silk Road",
    "XP1_002"       => "Altai Range",
    "XP1_003"       => "Guilin Peaks",
    "XP1_004"       => "Dragon Pass",
    "XP2_001"       => "Lost Islands",
    "XP2_002"       => "Nansha Strike",
    "XP2_003"       => "Wave Breaker",
    "XP2_004"       => "Operation Mortar",
    "XP3_MarketPl"  => "Pearl Market",
    "XP3_Prpganda"  => "Propaganda",
    "XP3_UrbanGdn"  => "Lumphini Garden",
    "XP3_WtrFront"  => "Sunken Dragon",
    "XP4_Arctic"    => "Operation Whiteout",
    "XP4_SubBase"   => "Hammerhead",
    "XP4_Titan"     => "Hangar 21",
    "XP4_WlkrFtry"  => "Giants Of Karelia",
    "XP5_Night_01"  => "Zavod: Graveyard Shift",
  }

end

class Army
  attr_reader :tickets

  def initialize data = {}, tickets
    @data, @tickets = data, tickets
  end

  def faction
    FACTIONS[faction_key]
  end

  def soldiers
    @soldiers ||= list_soldiers
    @soldiers.reject { |soldier| soldier.commander? }
  end

  def squads
    soldiers.group_by { |soldier| soldier.squad }
  end

  def score
    soldiers.inject(0) { |sum, solider| sum + solider.score }
  end

  def commander
    commander = soldiers.detect { |s| s.commander? }
    commander.nil? ? 'Unassigned' : commander.to_s
  end

  private

  def data
    @data
  end

  def faction_key
    data['faction']
  end

  def list_soldiers
    soldiers = []
    data['players'].each do |key, value|
      soldiers << Soldier.new( key, value )
    end
    soldiers
  end

  FACTIONS = %w(US RU CN)

end

class Game

  def initialize data = {}
    @data = data
  end

  def lobby
    joining_soldiers
  end

  def army_1
    Army.new army_1_data, army_1_tickets
  end

  def army_2
    Army.new army_2_data, army_2_tickets
  end

  def waiting_count
    waiting_players
  end

  def map
    BattlefieldMap.new( current_map ).name
  end

  def mode
    game_mode
  end

  def elapsed_time
    Time.at( round_time ).utc.strftime("%H:%M:%S")
  end

  def started?
    elapsed_time > '00:00:00'
  end

  def id
    game_id
  end

  private

  def data
    @data
  end

  def snapshot
    data['snapshot']
  end

  def current_map
    snapshot['currentMap']
  end

  def game_mode
    snapshot['gameMode']
  end

  def round_time
    snapshot['roundTime']
  end

  def game_id
    snapshot['gameId']
  end

  def waiting_players
    snapshot['waitingPlayers']
  end

  def team_info
    snapshot['teamInfo']
  end

  def lobby_data
    team_info['0']
  end

  def army_1_data
    team_info['1']
  end

  def army_1_tickets
    snapshot['conquest']['1']['tickets']
  end

  def army_2_data
    team_info['2']
  end

  def army_2_tickets
    snapshot['conquest']['2']['tickets']
  end

  def joining_soldiers
    soldiers = []
    lobby_data['players'].each do |key,value|
      soldiers << Soldier.new( key, value )
    end
    soldiers
  end

end

class Server
  attr_reader :name, :uuid

  def initialize data = {}
    @name = data[:name]
    @uuid = data[:uuid]
  end

  def valid?
    name.present? && uuid.present?
  end

  def snapshot
    APIv2.fetch self
  end

end

class APIv2
  include HTTParty
  base_uri 'keeper.battlelog.com'

  def self.fetch server
    APIv2.get "/snapshot/#{server.uuid}"
  end
end

puts 'Calling http://keeper.battlelog.com'

# server = Server.new name: 'some-unique-name-1', uuid: '4e54a287-4ae0-4622-ad63-b6a6f66fd4af'
server = Server.new name: 'Oaks-Clan-ESP-Conquest-All-Maps-Votemap', uuid: 'c154635c-2c53-44f8-864d-1c63ddc5fb24'
# server = Server.new name: 'www-twitch-tv-21cw-tournament', uuid: '624a8797-26bb-436f-92de-2a375c7268f0'
# server = Server.new name: 'Global-Conflict-org-EU-Server', uuid: '3ac44c83-df31-4bc4-bccb-fea4902a0304'

trap('INT') { puts 'Shutting down.'; exit }

while true do
  sleep_interval = 5

  response = server.snapshot
  puts response.code

  unless response.code == 200
    puts response.body
  else
    data = JSON.parse response.body

    begin
      game = Game.new data

      ap server.name
      ap game.id
      ap game.elapsed_time
      ap game.mode
      ap game.map

    rescue
      puts "Server Data unavailable..."
      sleep_interval *= 2
    end
  end

  sleep sleep_interval
end
