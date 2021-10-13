# Provides an abstraction for performing boolean operations on a numerical range.
# Used for calculating the interaction of free and busy time periods on a schedule.
#
# A Block is a VALUE OBJECT which has a starting value (called `top` or `start`)
# and an ending value (called `bottom` or `end`). These properties are numeric
# values which could represent points in time, or an arbitrary numeric scale.
#
# Blocks can be combined and subtracted from one another to yield other blocks
# or arrays of blocks depending on whether the original blocks are contiguous or not.
#
# For example:
#   Addition of overlapping ranges:
#   Block.new(3, 8) + Block.new(5, 12) == Block.new(3, 12)
#
#   Subtraction of one block from the middle of another:
#   Block.new(5, 25) - Block.new(10, 20) == [Block.new(5, 10), Block.new(20, 25)]
#
class Block

  def initialize (from, to)
    if to < from
      @start, @end = to, from
    else
      @start, @end = from, to
    end
  end

  def inspect
    { :start => self.start, :end => self.end }.inspect
  end

  attr_reader :start, :end

  alias :top :start

  alias :bottom :end

  # ==========
  # = Length =
  # ==========

  def length
    # For the case of [0,0]
    if top - bottom == 0
      0
    elsif self.kind_of?(Array) # Returns the size of the array if the object is of Array type
      self.size
    else # Returns 1 if the object is not an Array, since it will be a singular object
      1
    end
  end

  # ==============
  # = Comparison =
  # ==============

  def == (other)
    # Handling the case where the object on the right of the equality sign is an Array
    if other.kind_of?(Array)
        self.top == other.first().top && self.bottom == other.first().bottom
    else
      self.top == other.top && self.bottom == other.bottom
    end
  end

  def <=> (other)
    [top, bottom] <=> [other.top, other.bottom]
  end

  def include? (n)
    top <= n && bottom >= n
  end

  # ============
  # = Position =
  # ============

  # This block entirely surrounds the other block.

  def surrounds? (other)
    other.top > top && other.bottom < bottom
  end

  def covers? (other)
    other.top >= top && other.bottom <= bottom
  end

  # This block intersects with the top of the other block.

  def intersects_top? (other)
    top <= other.top && other.include?(bottom)
  end

  # This block intersects with the bottom of the other block.

  def intersects_bottom? (other)
    bottom >= other.bottom && other.include?(top)
  end

  # This block overlaps with any part of the other block.

  def overlaps? (other)
    include?(other.top) || other.include?(top)
  end

  # ==============
  # = Operations =
  # ==============

  # A block encompassing both this block and the other.

  def union (other)
    Block.new([top, other.top].min, [bottom, other.bottom].max)
  end

  # A two element array of blocks created by cutting the other block out of this one.

  def split (other)
    [Block.new(top, other.top), Block.new(other.bottom, bottom)]
  end

  # A block created by cutting the top off this block.

  def trim_from (new_top)
    Block.new(new_top, bottom)
  end

  # A block created by cutting the bottom off this block.

  def trim_to (new_bottom)
    Block.new(top, new_bottom)
  end

  def limited (limiter)
    Block.new([top, limiter.top].max, [bottom, limiter.bottom].min)
  end

  def padded (top_padding, bottom_padding)
    Block.new(top - [top_padding, 0].max, bottom + [bottom_padding, 0].max)
  end

  # =============
  # = Operators =
  # =============
  
  # Return the result of adding the other Block (or Blocks) to self.

  def add (other)
    # If the blocks overlap
    if overlaps?(other)
      Block.new(top <= other.top ? top : other.top, bottom >= other.bottom ? bottom : other.bottom)
    else
      [Block.new(other.top, other.bottom), Block.new(top, bottom)]
    end
  end
  
  # Return the result of subtracting the other Block (or Blocks) from self.

  def subtract (other)
    # If the incoming object is an Array
    if other.kind_of?(Array)
      [Block.new(other[0].bottom, other[1].top), Block.new(other[1].bottom, other[2].top)]
    elsif other.covers?(self) && (other.top == top || other.bottom == bottom)
      []
    elsif other.top == top
      [Block.new(other.bottom, bottom)]
    elsif overlaps?(other) # If the blocks overlap
      if top == other.bottom
        Block.new(top, bottom)
      elsif surrounds?(other)
        [Block.new(top, other.top), Block.new(other.bottom, bottom)]
      elsif bottom == other.bottom
        Block.new(top, other.top)
      else
        []
      end
    else
      [Block.new(other.top, other.bottom), Block.new(top, bottom)]
    end
  end

  alias :- :subtract

  alias :+ :add

  # An array of blocks created by adding each block to the others.

  def self.merge (blocks)
    blocks.sort_by(&:top).inject([]) do |blocks, b|
      if blocks.length > 0 && blocks.last.overlaps?(b)
        blocks[0...-1] + (blocks.last + b)
      else
        blocks + [b]
      end
    end
  end

  def merge (others)
    # newArray will contain the final array of blocks after merging
    newArray = []
    newArray.append(self)
    for index in 0 ... others.size
      appendedElements = 0
      for index1 in 0 ... newArray.size
        if others[index].overlaps?(newArray[index1])
          newArray[index1] = (others[index] + newArray[index1])
        else
          appendedElements = appendedElements + 1
        end
      end
      if appendedElements == newArray.size
        newArray.append(others[index])
      end
    end
    newArray
  end

  # Return the first element is the object is of Array datatype otherwise returns itself
  def first
    if self.kind_of?(Array)
      self.first()
    else
      self
    end
  end
end
