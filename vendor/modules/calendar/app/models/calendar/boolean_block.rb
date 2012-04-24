
class Calendar::BooleanBlock 

  def initialize()
    @blocks = []

  end
  
  def add(arr)
    # Add the new block
    added = arr.collect { |blk| blk + [true] }
    merge(added)
  end
  
  def merge(arr)
    @blocks += arr
    # Make sure blocks are in start order
    @blocks.sort! { |a,b| a[0] <=> b[0] }
    @blocks = @blocks.inject([]) do |blks,block|
      if blks.length == 0
        [ block ]
      else
        last_block = blks[-1]
        if(block[0] > last_block[1])
          blks + [block]
        elsif (block[1] <= last_block[1])
          blks
        else
          last_block[1] = block[1]
          blks
        end
      end
    end
    
  end
  
  # Join adds together two 'true' blocks, but doesn't union them
  # (i.e. the availabilities stay separate) 
  # We only have true blocks
  def join(arr)
   @blocks += arr
    @blocks.sort! { |a,b| a[0] <=> b[0] }
    @blocks = @blocks.inject([]) do |blks,block|
      if blks.length == 0
        [ block ]
      else
        last_block = blks[-1]
        if(block[0] >= last_block[1])  
          # no overlay, return block separately
          blks + [block]
        elsif (block[1] <= last_block[1])
          # if we have containment, just get rid of the current block
          blks
        else
          # Otherwise we have a partial overlay
          # if just slice out the last block
          last_block[1] = block[0]
          blks + [block]
        end
      end
    
    end 
  end
  
  
  def remove(arr)
    @blocks += arr.collect { |blk| blk + [false] }
    @blocks.sort! { |a,b| a[0] <=> b[0] }
    
    @blocks = @blocks.inject([]) do |blks,block|
      if blks.length == 0
        [ block ]
      else
        last_block = blks[-1]
        if(block[0] >= last_block[1])  
          # no overlay, return block separately
          blks + [ block]
        elsif (block[1] <= last_block[1])
          # If contained, check to see the overlay type
          if last_block[3] || !block[3]
            # if the last block is a true block, or the current block is a false block carve it up into two
            # as long as this block starts after the last block
            if block[0] > last_block[0]
              new_block = [ block[1], last_block[1], last_block[2], last_block[3] ]
              last_block[1] = block[0]
              blks + [block,new_block]
            # otherwise kill the start of the cur block,
            # and add the current block in front of the last block
            else
              last_block[0] = block[1]
              blks[0..-2] + [ block,last_block ]
              
            end
          else
            # Otherwise we have a true block inside of a false block, so kill the false block
            blks
          end
        else
          # Otherwise we have a partial overlay
          if !block[3]
           # if the current block is a false block, we are slicing out of last_block
           last_block[1] = block[0]
           blks + [block]
          else
           # otherwise we are slicing out of the current block
           block[0] = last_block[1]
           blks + [block]
          end
        end
      end
    
    end
  
  end

  def to_a
    @blocks
  end


end
