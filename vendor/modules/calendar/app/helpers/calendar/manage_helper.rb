

module Calendar::ManageHelper 



  def calendar_block_style(block,offset_x=0,offset_y=0,options={})

    "display:block; position:absolute; left:#{block[:x]+offset_x}px; top:#{block[:y]+offset_y}px;  width:#{block[:width]}px; height:#{block[:height]}px; background-color: #{options[:color] || block[:color]}"
  end
  
  def calendar_full_block_style(block,offset_x=0,offset_y=0,options={})
    "display:block; position:absolute; left:#{offset_x}px; top:#{offset_y}px;  width:#{block[:width]}px; height:#{options[:height]}px; background-color: #{options[:color] || block[:color]}"
  end

  def compare_booking(slot,prev_slot) 
    slot[3] || !prev_slot || !slot[2] || !prev_slot[2] || (slot[2].id != prev_slot[2].id)   
  end
end
