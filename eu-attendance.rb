#! /usr/bin/env ruby -w

# http://www.nathan-dev.com/projects/bf4_scoreboard/scoreboard.php?guid=3ac44c83-df31-4bc4-bccb-fea4902a0304
# http://battlelog.battlefield.com/bf4/servers/show/pc/3ac44c83-df31-4bc4-bccb-fea4902a0304/Global-Conflict-org-EU-Server/

require 'rubygems'

require 'rest-client'
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
  }

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
    data['players'].each do |key,value|
      soldiers << Soldier.new( key, value )
    end
    soldiers
  end

  FACTIONS = %w(US RU CN)

end

def center message
  (' ' * (39 - message.size / 2)) + message
end

puts "Calling http://keeper.battlelog.com"

servers = {
  '3ac44c83-df31-4bc4-bccb-fea4902a0304' => 'Global-Conflict-org-EU-Server',
  'eb414b20-dc82-4058-9ae1-c6ca610d845e' => 'Global-Conflict-org-US-Server',
}

# uuid = "eb414b20-dc82-4058-9ae1-c6ca610d845e"
# uuid = "3ac44c83-df31-4bc4-bccb-fea4902a0304"
# uuid = "26edcc9f-172e-445c-b25f-649f099939e3"
uuid = servers.keys.first
keeper_url = "http://keeper.battlelog.com/snapshot/#{uuid}"

trap("INT") { puts "Shutting down."; exit }

today = Date.today.strftime("%Y-%m-%d")
battle_reports_location = "./battle_reports/#{today}/#{servers[servers.keys.first]}"
FileUtils.mkdir_p battle_reports_location

puts "Saving battle reports in #{battle_reports_location}"

while true do
  sleep_interval = 60

  response = RestClient.get keeper_url

  puts response.code
  data = JSON.parse response
  # ap data

  begin
    game = Game.new data

    header = []
    body = []
    header << "================================================================================"
    header << ( "%-32s%-30s%18s" % [game.map, game.mode, game.elapsed_time] )
    header << "--------------------------------------------------------------------------------"
    header << (center "Army 1 (#{game.army_1.faction}) vs. Army 2 (#{game.army_2.faction})")
    header << (center "#{game.army_1.faction} - #{game.army_1.tickets} vs. #{game.army_2.faction} - #{game.army_2.tickets}")
    header << (center "#{game.army_1.faction} - #{game.army_1.score} vs. #{game.army_2.faction} - #{game.army_2.score}")
    header << "--------------------------------------------------------------------------------"
    header << "Soldiers Waiting: #{game.waiting_count}"
    header << "Soldiers Joining: #{game.lobby.size}"
    unless game.lobby.empty?
      header << "--------------------------------------------------------------------------------"
      header << "Joining:"
      game.lobby.each do |soldier|
        header << "\t#{soldier}"
      end
    end
    header << "--------------------------------------------------------------------------------"
    player_count = ('%20s%40s%-20s' % ["Army 1 Players: #{game.army_1.soldiers.size}", "", "Army 2 Players: #{game.army_2.soldiers.size}"])
    header << player_count
    body << "--------------------------------------------------------------------------------"
    body << " Army 1 Commander: #{game.army_1.commander}"
    body << " Army 2 Commander: #{game.army_2.commander}"
    body << "--------------------------------------------------------------------------------"
    body << (center "Army 1 Attendance:")
    army_1_attendance = game.army_1.soldiers.group_by { |soldier| soldier.tag }
    army_1_attendance.keys.sort_by { |k| k.downcase }.each do |key|
      body << "[#{key.empty? ? 'none' : key}]"
      soldiers = army_1_attendance[key]
      soldiers.sort_by { |s| s.name.downcase }.each do |soldier|
        body << "\t#{soldier.name}"
      end
    end
    body << "--------------------------------------------------------------------------------"
    body << (center "Army 2 Attendance:")
    army_2_attendance = game.army_2.soldiers.group_by { |soldier| soldier.tag }
    army_2_attendance.keys.sort_by { |k| k.downcase }.each do |key|
      body << "[#{key.empty? ? 'none' : key}]"
      soldiers = army_2_attendance[key]
      soldiers.sort_by { |s| s.name.downcase }.each do |soldier|
        body << "\t#{soldier.name}"
      end
    end
    body << "================================================================================"

    if game.started?
      game_report_location = "#{battle_reports_location}/#{game.map.gsub(/ /,'')}"
      FileUtils.mkdir_p game_report_location
      battle_report_name = "#{game_report_location}/#{Time.now.utc.to_i}.report"
      File.open( battle_report_name, 'w' ) do |file|
        header.each do |line|
          file.puts line
        end
        body.each do |line|
          file.puts line
        end
      end
      puts header.join("\n")
      puts "================================================================================"
    else
      puts "Game has not started..."
      sleep_interval = 5
    end

  rescue
    puts "Server Data unavailable..."
    sleep_interval = 5
  end

  sleep sleep_interval
end
