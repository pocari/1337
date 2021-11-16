FromTo = Struct.new(:from, :to) do
  def inspect
    "#{from}-#{to}"
  end

  def to_s
    inspect
  end

  def pretty_print(q)
    q.pp inspect
  end
end

def paren_pattern(n, size, offset = 0)
  # p [:paren_pattern, n, size, offset]
  if size < 2
    []
  else
    last_index = offset + n - 1
    (offset .. last_index - size + 1).flat_map do |from|
      to = from + size - 1
      ft = FromTo.new(from, to)

      # まずsize子の数字を囲むカッコの位置を確定
      #  0, 1, 2, 3 に対して
      # (0, 1, 2), 3 みたいなパターンをここではFromTo.new(0, 2)と表現している
      base1 = [[ft]]

      # 次に、base1の中に入れ子でカッコを入れられる場合のパターンを探す
      # base1が(0, 1, 2)だとして、 ((0, 1), 2) や (0, (1, 2)) というパターンを探す
      base2 = paren_pattern(size, size - 1, from).map do |pattern|
        [ft, *pattern]
      end

      # 最後に、今確定したbase1より後の部分に関してカッコをいれられるかどうかを確認
      # base1が(0, 1)だとして、 (2, 3) みたいなパターンを探す
      next_size = last_index - to
      base3 = paren_pattern(next_size, next_size, to + 1).flat_map do |pattern|
        (base1 + base2).map do |b|
          [*b, *pattern]
        end
      end

      base1 + base2 + base3
    end
  end
end

def paren_pattern_all(n, offset = 0)
  (2 .. n - 1).flat_map do |size|
    paren_pattern(n, size, offset)
  end
end

def expression_patterns_helper(n, rest, acc_nums = [], acc_ops = [])
  if rest.size == 0
    [[acc_nums + [n], acc_ops]]
  else
    [n, -n].flat_map do |num|
      %w[+ - * /].flat_map do |op|
        expression_patterns_helper(rest[0], rest[1..-1], acc_nums + [num], acc_ops + [op])
      end
    end
  end
end

def expression_patterns(nums)
  expression_patterns_helper(nums[0], nums[1 .. -1])
end

def apply_paren(paren_info, exp)
  nums = exp[0].map { |n| n < 0 ? "(#{n})" : "#{n}" }
  ops = exp[1]

  paren_info.each do |ft|
    nums[ft.from] = "(#{nums[ft.from]}"
    nums[ft.to] = "#{nums[ft.to]})"
  end

  [nums, ops]
end

def gen_expression(nums)
  pattern_patterns = paren_pattern_all(nums.size)
  expressions = nums.permutation.flat_map do |perm|
    expression_patterns(perm)
  end

  expressions.each do |exp|
    pattern_patterns.each do |pattern|
      yield apply_paren(pattern, exp)
    end
  end
end

def main
  gen_expression([1, 3, 3, 7]) do |nums, ops|
    # numsの方が必ず1つおおいので、それを考慮して、numsに対して、opsをzipする
    expression = nums.zip(ops).flatten.join
    # ZeroDivisionErrorが発生した場合は、無視する
    begin
      result = eval(expression)
      if result == 10
        puts expression
      end
    rescue ZeroDivisionError
    end
  end
end

main