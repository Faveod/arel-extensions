# Arel Extensions

[![Build Status](https://secure.travis-ci.org/Faveod/arel-extensions.svg)](http://travis-ci.org/Faveod/arel-extensions)
[![Latest Release](https://img.shields.io/gem/v/arel_extensions.svg)](https://rubygems.org/gems/arel_extensions)
![](http://img.shields.io/badge/license-MIT-brightgreen.svg)
![](https://ruby-gem-downloads-badge.herokuapp.com/arel_extensions?type=total)
![](https://ruby-gem-downloads-badge.herokuapp.com/arel_extensions?label=downloads-current-version)

Arel Extensions adds shortcuts, fixes and new ORM mappings (ruby to SQL) to Arel.
It aims to ensure pure ruby syntax for the biggest number of usual cases.
It allows to use more advanced SQL functions for any supported RDBMS.


## Requirements

Arel 6 (Rails 4) or Arel 7+ (Rails 5).


## Examples

t is an Arel::Table for table my_table

## Comparators

```ruby
(t[:date1] > t[:date2]).to_sql # (same as (t[:date1].gt(t[:date2])).to_sql)
# => my_table.date1 > my_table.date2
```

```ruby
(t[:nb] > 42).to_sql # (same as (t[:nb].gt(42)).to_sql)
# => my_table.nb > 42
```

Other operators : <, >=, <=, =~


## Maths

Currently in Arel:
```ruby
(t[:nb] + 42).to_sql
# => my_table.nb + 42
```

But:
```ruby
(t[:nb].sum + 42).to_sql
# => NoMethodError: undefined method `+' for #<Arel::Nodes::Sum>
```

With Arel Extensions:
```ruby
(t[:nb].sum + 42).to_sql
# => SUM(my_table.nb) + 42
```

Other functions : ABS, RAND, ROUND, FLOOR, CEIL, FORMAT

## String operations

```ruby
(t[:name] + ' append').to_sql
# => CONCAT(my_table.name, ' append')

(t[:name].coalesce('default')).to_sql
# => COALESCE(my_table.name, 'default')

(t[:name].blank).to_sql
# => TRIM(TRIM(TRIM(COALESCE(my_table.name, '')), '\t'), '\n') = ''

(t[:name] =~ /\A[a-d_]+/).to_sql
# => my_table.name REGEXP '\^[a-d_]+'
```

Other functions : SOUNDEX, LENGTH, REPLACE, LOCATE, TRIM

### String Array operations

```t[:list]``` is a classical varchar containing a comma separated list ("1,2,3,4")

```ruby
(t[:list] & 3).to_sql
# => FIND_IN_SET('3', my_table.list)

(t[:list] & [2,3]).to_sql
# => FIND_IN_SET('2', my_table.list) OR FIND_IN_SET('3', my_table.list)
```


## Date & Time operations

```ruby
(t[:birthdate] + 10.years).to_sql
# => ADDDATE(my_table.birthdate, INTERVAL 10 YEAR)

((t[:birthdate] - Date.today) * -1).to_sql
# => DATEDIFF(my_table.birthdate, '2017-01-01') * -1

t[:birthdate].week.to_sql
# => WEEK(my_table.birthdate)

t[:birthdate].month.to_sql
# => MONTH(my_table.birthdate)

t[:birthdate].year.to_sql
# => YEAR(my_table.birthdate)

t[:birthdate].format('%Y-%m-%d').to_sql
# => DATE_FORMAT(my_table.birthdate, '%Y-%m-%d')
```

## Unions (in next version)

```ruby
(t.where(t[:name].eq('str')) + t.where(t[:name].eq('test'))).to_sql
# => SELECT * FROM my_table WHERE (name = 'str') UNION SELECT * FROM my_table WHERE (name= 'test')
```

## Stored Procedures and User-defined functions

To optimize queries, some classical functions are defined in databases missing any alternative native functions.
Examples :
- FIND_IN_SET 

## BULK INSERT / UPSERT

Arel Extensions improves InsertManager by adding bulk_insert method, which allows to insert multiple rows in one insert.


```
@cols = ['id', 'name', 'comments', 'created_at']
@data = [
   	[23, 'name1', "sdfdsfdsfsdf", '2016-01-01'],
   	[25, 'name2', "sdfds234sfsdf", '2016-01-01']
]

insert_manager = Arel::InsertManager.new(User).into(User.arel_table)
insert_manager.bulk_insert(@cols, @data)
User.connection.execute(insert_manager.to_sql)
```