Nonterminals file msgdef message_body extend_body service_body group_body enum_body
             field_spec field_rule option_spec options option_list
             name type_name keyword value.
Terminals bareword number string
          import package option message group enum extend service rpc
          required optional repeated returns extensions max to
          true false
          ';' '=' ',' '(' ')' '[' ']' '{' '}'.
Rootsymbol file.
Endsymbol '$end'.

file -> '$empty' : [].
file -> import string ';' file : [{import, value_of('$2')}|'$4'].
file -> package name ';' file : [{package, '$2'}|'$4'].
file -> option_spec file : ['$1'|'$2'].
file -> service name '{' service_body '}' file : [{service, '$2', lists:reverse('$4')}|'$6'].
file -> msgdef file : ['$1'|'$2'].

msgdef -> message type_name '{' message_body '}' : {message, '$2', lists:reverse('$4')}.
msgdef -> extend type_name '{' extend_body '}' : {extend, '$2', lists:reverse('$4')}.
msgdef -> enum type_name '{' enum_body '}' : {enum, '$2', lists:reverse('$4')}.

message_body -> '$empty' : [].
message_body -> field_spec message_body : ['$1'|'$2'].
message_body -> msgdef message_body : ['$1'|'$2'].
message_body -> option_spec message_body : ['$1'|'$2'].
message_body -> extensions number to max ';' message_body : [{extensions, '$2', max}|'$6'].
message_body -> extensions number to number ';' message_body : [{extensions, '$2', '$4'}|'$6'].

enum_body -> '$empty': [].
enum_body -> name '=' value options ';' enum_body : [{enum_value, '$1', '$3', '$4'}|'$6'].
enum_body -> option_spec enum_body : ['$1'|'$2'].

group_body -> '$empty' : [].
group_body -> field_spec group_body : ['$1'|'$2'].

extend_body -> '$empty' : [].
extend_body -> field_spec extend_body : ['$1'|'$2'].

service_body -> '$empty' : [].
service_body -> rpc name '(' type_name ')' returns '(' type_name ')' options ';' service_body :
  [{rpc, {'$2', '$4', '$8', '$10'}}|'$12'].
service_body -> option_spec service_body : ['$1'|'$2'].

field_spec -> field_rule type_name name '=' number options ';' :
  {field, '$1', '$2', '$3', '$5', '$6'}.
field_spec -> field_rule group name '=' number '{' group_body '}' :
  {field, '$1', {group, lists:reverse('$7')}, '$3', '$5', []}.

field_rule -> required : required.
field_rule -> optional : optional.
field_rule -> repeated : repeated.

option_spec -> option name '=' value ';' : {option, '$2', '$4'}.

options -> '$empty': [].
options -> '[' option_list ']' : '$2'.

option_list -> '$empty' : [].
option_list -> name '=' value : [{'$1', '$3'}].
option_list -> name '=' value ',' option_list : [{'$1', '$3'}|'$5'].

value -> string : value_of('$1').
value -> number : value_of('$1').
value -> true : true.
value -> false : false.
value -> name : {symbol, '$1'}.

name -> bareword : value_of('$1').
name -> keyword : value_of('$1').
name -> group : "group".

type_name -> bareword : value_of('$1').
type_name -> keyword : value_of('$1').

keyword -> import.
keyword -> package.
keyword -> option.
keyword -> message.
keyword -> enum.
keyword -> extend.
keyword -> service.
keyword -> rpc.
keyword -> required.
keyword -> optional.
keyword -> repeated.
keyword -> returns.
keyword -> extensions.
keyword -> max.
keyword -> to.

Erlang code.

value_of({string, _Line, String}) ->
    String;
value_of({number, _Line, Number}) ->
    Number;
value_of({bareword, _Line, String}) ->
    String;
value_of({Keyword, _Line}) ->
    atom_to_list(Keyword).
