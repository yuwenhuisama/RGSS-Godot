output = $rgss_compat_output || '.'
classes = ['Actor','Animation','Animation::Frame','Animation::Timing','Armor',
  'AudioFile','BaseItem','BaseItem::Feature','BGM','BGS','Class','Class::Learning',
  'CommonEvent','Enemy','Enemy::Action','Enemy::DropItem','EquipItem','Event',
  'Event::Page','Event::Page::Condition','Event::Page::Graphic','EventCommand',
  'Item','Map','Map::Encounter','MapInfo','ME','MoveCommand','MoveRoute','SE',
  'Skill','State','System','System::Terms','System::Vehicle','System::TestBattler',
  'Tileset','Troop','Troop::Member','Troop::Page','Troop::Page::Condition',
  'UsableItem','UsableItem::Damage','UsableItem::Effect','Weapon']
describe = nil
describe = lambda do |value|
  if value.is_a?(Table)
    ['Table', value.xsize, value.ysize, value.zsize].join(':')
  elsif value.is_a?(Array)
    '[' + value.map { |entry| describe.call(entry) }.join(',') + ']'
  elsif value.is_a?(Hash)
    '{' + value.keys.sort.map { |key| describe.call(key) + '=>' + describe.call(value[key]) }.join(',') + '}'
  elsif value.is_a?(Color)
    ['Color', value.red, value.green, value.blue, value.alpha].join(':')
  elsif value.is_a?(String) || value.is_a?(Numeric) || value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.nil?
    value.inspect
  else
    value.class.to_s
  end
end
File.open(File.join(output, 'rpg_defaults_reference.tsv'), 'w') do |file|
  classes.each do |name|
    klass = name.split('::').inject(RPG) { |parent, part| parent.const_get(part) }
    args = name == 'Map' ? [3, 2] : name == 'Event' ? [1, 2] : []
    object = klass.new(*args)
    fields = object.instance_variables.sort
    file.puts [name, 'fields', fields.join(',')].join("\t")
    fields.each do |field|
      value = object.instance_variable_get(field)
      description = describe.call(value)
      getter = field.to_s[1..-1]
      file.puts [name, field, description, object.respond_to?(getter), object.respond_to?(getter + '=')].join("\t")
    end
    file.flush
  end
end
exit unless $rpg_defaults_host
