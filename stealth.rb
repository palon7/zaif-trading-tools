#!/usr/bin/env ruby
# encoding: utf-8

require 'thor'
require './config.rb'

class MyConsole < Thor
  desc "bid CURRENCY PRICE AMOUNT", "Issue stealth bid order. ex. ./stealth.rb bid mona 15.3 100"
  def bid(currency, price, amount)
      puts "Waiting for bid order: #{amount} #{currency} for #{price} JPY..."
  end

  private
  def run(currency, price, amount, type)
    
  end
end

MyConsole.start(ARGV)
