output = $rgss_compat_output || '.'
original = !$shop_name_host
if original
  DataManager.load_database
  DataManager.create_game_objects
  $game_party.setup_starting_members
end
saved_gold = $game_party.gold
item = RPG::Item.new
item.id = $data_items.size
item.name = 'Compatibility Potion'
item.price = 41
$data_items << item
shop = Scene_Shop.new
gold_window = Window_Gold.new
buy_window = Window_ShopBuy.new(0, 0, 200, [[0, item.id, 1, 40]])
shop.instance_variable_set(:@gold_window, gold_window)
shop.instance_variable_set(:@buy_window, buy_window)
shop.instance_variable_set(:@item, item)
File.open(File.join(output, 'shop_name_reference.tsv'), 'w') do |file|
  [0, 39, 40, 80, 40000].each do |gold|
    $game_party.gain_gold(gold - $game_party.gold)
    file.puts ['max-buy', gold, shop.max_buy].join("\t")
  end
  $game_party.gain_gold(200 - $game_party.gold)
  shop.do_buy(2)
  file.puts ['buy-two', $game_party.gold, $game_party.item_number(item), shop.max_sell].join("\t")
  shop.do_sell(1)
  file.puts ['sell-one', $game_party.gold, $game_party.item_number(item), shop.selling_price].join("\t")
  $game_party.gain_item(item, 98)
  file.puts ['full-inventory', shop.max_buy].join("\t")
  actor = $game_party.members[0]
  saved_name = actor.name
  actor.name = 'AB'
  edit = Window_NameEdit.new(actor, 3)
  file.puts ['back', edit.back, edit.name, edit.index].join("\t")
  file.puts ['add', edit.add('C'), edit.name, edit.index].join("\t")
  file.puts ['add-max', edit.add('D'), edit.name, edit.index].join("\t")
  file.puts ['over-max', edit.add('E'), edit.name, edit.index].join("\t")
  3.times { edit.back }
  file.puts ['empty-back', edit.back, edit.name, edit.index].join("\t")
  file.puts ['restore', edit.restore_default, edit.name, edit.index].join("\t")
  edit.dispose
  actor.name = saved_name
end
gold_window.dispose
buy_window.dispose
$game_party.lose_item(item, 99)
$data_items.pop
$game_party.gain_gold(saved_gold - $game_party.gold)
exit if original
