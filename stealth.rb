#!/usr/bin/env ruby
# encoding: utf-8

require 'etwings'
require 'thor'

if !File.exist?("./config.rb")
    puts "*** ERROR ***\n" + "Config file not found. Please rename \"config.default.rb\" to \"config.rb\" and define config."
    exit
end
require './config.rb'


class MyConsole < Thor
    desc "bid CURRENCY PRICE AMOUNT", "Issue stealth bid(buy) order. ex. ./stealth.rb bid mona 15.3 100"
    def bid(currency, price, amount)
        run(currency, price.to_f, amount.to_i, "bid")
    end
    desc "ask CURRENCY PRICE AMOUNT", "Issue stealth ask(sell) order. ex. ./stealth.rb ask mona 15.3 100"
    def ask(currency, price, amount)
        run(currency, price.to_f, amount.to_i, "ask")
    end

    private
    def run(currency, target_price, target_amount, type)
        error("API Key not defined. Please define at \"config.rb\".") if ETWINGS_KEY.empty? || ETWINGS_SECRET.empty?
        etwings = Etwings::API.new(:api_key => ETWINGS_KEY , :api_secret => ETWINGS_SECRET, :cool_down => false)
        currency_pair = currency + "_jpy"
        # check type

        direction = "" # 参照する板
        case type
        when "bid"
            direction = "asks"
            compare = lambda{|price,target| return price <= target} # 価格 >= 目標価格の時
        when "ask"
            direction = "bids"
            compare = lambda{|price,target| return price >= target} # 価格 <= 目標価格の時
        else
            error("Invalid type") 
        end

        # cleanup order
        puts "Cleanup order..."
        etwings.get_active_orders(:currency_pair => currency_pair).each{|k, v|
            if v["action"] == type && compare.call(v["price"], target_price)
                puts "Cancel order ##{k}: #{v["action"]} @ #{v["price"]}"
                etwings.cancel(k)
            end
        }
        sleep 2

        proccesing = false

        # watch loop
        loop{
            puts "Waiting for #{type} order: #{target_amount} #{currency} for #{target_price} JPY..."
            orders = etwings.get_depth(currency)
            puts "Proccesing..."
            # order process
            orders[direction].each{|v|
                price,amount = v[0], v[1]

                # 目的数量注文済みなら抜ける
                break if target_amount <= 0

                # 目的価格より条件の良い価格でなければ抜ける
                break if !compare.call(price, target_price)
                
                if amount < target_amount
                    # 目的数量より少ないならすべてを取引
                    trade_amount = amount
                else
                    # 目的数量以上なら目的数量のみ取引
                    trade_amount = target_amount
                end

                # 取引
                #etwings.trade(currency, price, trade_amount, type)
                
                # 目的数量から取引分を減らす
                target_amount -= trade_amount
                proccesing = true
                puts "#{type} #{trade_amount} #{currency} @ #{price}, left: #{target_amount}"
            }
            

            # cancel order
            if proccesing
                puts "Check for cancel order..."
                sleep 2
                etwings.get_active_orders(:currency_pair => currency_pair).each{|k, v|
                    if v["action"] == type && compare.call(v["price"], target_price)
                        puts "Cancel order ##{k}: #{v["action"]} @ #{v["price"]}"
                        etwings.cancel(k)
                        target_amount = target_amount + v["amount"]
                    end
                }
                proccesing = false
            end

            if target_amount <= 0
                puts "Trade complete."
                exit
            end

            print_table(orders[direction]) if SHOW_TABLE
            sleep FETCH_INTERVAL
        }
    end

    def print_table(data)
        printf "+-----------+------------------+\n"
        printf("|%10s |%17s |\n", "Price", "Amount")
        printf "+-----------+------------------+\n"
        data[0,5].each{|v|
            printf("|%10.1f |%17.8f |\n", v[0], v[1])
        }
        printf "+-----------+------------------|\n"
    end

    def error(message)
        puts "*** Error ***\n" + message
        exit
    end

end

MyConsole.start(ARGV)
