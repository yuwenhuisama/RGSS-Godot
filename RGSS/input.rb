# encoding: utf-8
require 'type_check_util'

module Input
  DOWN = :DOWN
  LEFT = :LEFT
  RIGHT = :RIGHT
  UP = :UP

  A = :A
  B = :B
  C = :C
  X = :X
  Y = :Y
  Z = :Z
  L = :L
  R = :R

  SHIFT = :SHIFT
  CTRL = :CTRL
  ALT = :ALT

  F5 = :F5
  F6 = :F6
  F7 = :F7
  F8 = :F8
  F9 = :F9
end

module Input
  extend TypeCheckUtil

  VALID_KEYS = Set.new([DOWN, LEFT, RIGHT, UP, A, B, C, X, Y, Z, L, R, SHIFT, CTRL, ALT, F5, F6, F7, F8, F9])

  def self.press?(key)
    VALID_KEYS.include?(key) ? Unity::Input.press?(key) : false
  end

  def self.trigger?(key)
    VALID_KEYS.include?(key) ? Unity::Input.trigger?(key) : false
  end

  def self.repeat?(key)
    VALID_KEYS.include?(key) ? Unity::Input.repeat?(key) : false
  end

  [:update, :dir4, :dir8].each { |prop| define_singleton_method(prop) { Unity::Input.send(prop) } }
end
