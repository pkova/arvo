::
=,  ethe
=,  ethereum
::
=|  addr=address
=|  gas-price=@ud
=|  network=@ux
=|  now=@da
::
|_  $:  nonce=@ud                                       ::  next tx id
        transactions=(list transaction)                 ::  generated txs
        constitution=address                            ::  deployed address
    ==
::
++  this  .
::
+$  rights
  $:  own=address
      manage=(unit address)
      voting=(unit address)
      transfer=(unit address)
      spawn=(unit address)
      net=(unit [crypt=@ux auth=@ux])
  ==
::
++  tape-to-ux
  |=  t=tape
  (scan t zero-ux)
::
++  zero-ux
  ;~(pfix (jest '0x') hex)
::
++  ship-and-rights
  |=  live=?
  ;~  (glue com)
    ;~(pfix sig fed:ag)
    (all-rights live)
  ==
::
++  all-rights
  |=  live=?
  ;~  (glue com)
    zero-ux
    (punt zero-ux)
    (punt zero-ux)
    (punt zero-ux)
    (punt zero-ux)
  ::
    =+  ;~(plug zero-ux ;~(pfix com zero-ux))
    ?.  live  (punt -)
    (stag ~ -)
    :: %.  ;~(plug zero-ux ;~(pfix com zero-ux))
    :: ^-  $-(rule rule)
    :: ?.  live  punt
    :: (cury stag ~)
  ==
::
++  get-file
  |=  pax=path
  ~|  pax
  .^  (list cord)  %cx
      (weld /(scot %p ~zod)/home/(scot %da now) pax)
  ==
::
++  parse-lines
  |*  [fil=knot par=rule]
  %+  turn  (get-file /[fil]/txt)
  |=  c=cord
  ~|  c
  (rash c par)
::
++  order-shiplist
  |=  [[a=ship *] [b=ship *]]
  (lth a b)
::
++  init
  |=  [n=@da g=@ud non=@ud addr=address]
  ^+  this
  %_  this
    now         n
    nonce       non
    gas-price   g
    addr        addr
  ==
::
++  get-direct-galaxies
  ^-  (list [who=ship rights])
  %+  parse-lines  'direct-galaxies'
  (ship-and-rights |)
::
++  get-direct-ships
  ^-  (list [who=ship rights])
  %+  parse-lines  'direct-ships'
  (ship-and-rights |)
::
++  get-linear-recipients
  ^-  %-  list
      $:  recipient=address
          windup=@ud
          stars=@ud
          rate=@ud
          rate-unit=@ud
      ==
  %+  parse-lines  'linear-recipients'
  ;~  (glue com)
    zero-ux
    dum:ag
    dum:ag
    dum:ag
    dum:ag
  ==
::
++  get-conditional-recipients
  ^-  %-  list
      $:  recipient=address
          b1=@ud
          b2=@ud
          b3=@ud
          rate=@ud
          rate-unit=@ud
      ==
  %+  parse-lines  'conditional-recipients'
  ;~  (glue com)
    zero-ux
    dum:ag
    dum:ag
    dum:ag
    dum:ag
    dum:ag
  ==
::
++  get-locked-galaxies
  |=  type=@t
  ^-  (list [who=ship rights])
  ~|  type
  %+  parse-lines  (cat 3 type '-galaxies')
  (ship-and-rights &)
::
++  get-locked-stars
  |=  type=@t
  ^-  (list [who=ship recipient=address])
  ~|  type
  %+  parse-lines  (cat 3 type '-stars')
  ;~  (glue com)
    ;~(pfix sig fed:ag)
    zero-ux
  ==
::
++  write-tx
  |=  tx=transaction
  ^+  this
  this(transactions [tx transactions])
::
++  complete
  ~&  [%writing-transactions (lent transactions)]
  (flop transactions)
::
++  get-contract-address
  =+  dat=(encode-atoms:rlp:ethereum ~[addr nonce])
  =+  wid=(met 3 dat)
  %^  end  3  20
  (keccak-256:keccak:crypto wid (rev 3 wid dat))
::
++  do-deploy
  |=  [wat=cord arg=(list data)]
  ^-  [address _this]
  ~&  [`@ux`get-contract-address +(nonce)]
  :-  get-contract-address
  %^  do  0x0  6.000.000
  =+  cod=(get-file /contracts/[wat]/txt)
  ?>  ?=(^ cod)
  %-  tape-to-ux
  (weld (trip i.cod) (encode-args arg))
::
++  do
  ::TODO  maybe reconsider encode-call interface, if we end up wanting @ux
  ::      as or more often than we want tapes
  |=  [to=address gas=@ud dat=$@(@ux tape)]
  ^+  this
  %-  write-tx(nonce +(nonce))
  :*  nonce
      gas-price
      6.000.000
      to
      0
      `@`?@(dat dat (tape-to-ux dat))
      network
  ==
::
++  sequence
  |=  [won=@da net=?(%fake %main %ropsten) gasp=@ud non=@ud addr=address]
  =.  this  (init(now won) won gasp non addr)
  =.  network
    ?+  net  0x1
      %ropsten  0x3
      %fake     `@ux``@`1.337
    ==
  ::
  ::  data loading
  ::
  ::NOTE  we do these first so that we are sure we have sane files,
  ::      without waiting for that answer
  ::X =+  tlon-gal=get-direct-galaxies
  ::X =+  directs=get-direct-ships
  ::
  =+  lin-rec=get-linear-recipients
  =+  lin-gal=(get-locked-galaxies 'linear')
  ::X =+  lin-sar=(get-locked-stars 'linear')
  ::
  ::X =+  con-rec=get-conditional-recipients
  ::X =+  con-gal=(get-locked-galaxies 'conditional')
  ::X =+  con-sar=(get-locked-stars 'conditional')
  ::
  ~&  'Deed data sanity check...'
  ::X =/  tlon-map=(map ship rights)
  ::X   (~(gas by *(map ship rights)) tlon-gal)
  ::X =/  deed-map=(map ship rights)
  ::X   (~(gas by *(map ship rights)) directs)
  ::X =/  star-map=(map ship (set ship))
  ::X   %+  roll  directs
  ::X   |=  [[who=ship *] smp=(map ship (set ship))]
  ::X   ^+  smp
  ::X   =+  par=(^sein:title who)
  ::X   ~|  [%need-parent par %for who]
  ::X   ?>  ?&  ?|  (~(has by tlon-map) par)
  ::X               (~(has by deed-map) par)
  ::X           ==
  ::X         ::
  ::X           ?=  ^
  ::X           =<  net
  ::X           %+  fall
  ::X             (~(get by deed-map) par)
  ::X           %+  fall
  ::X             (~(get by tlon-map) par)
  ::X           *rights
  ::X       ==
  ::X   %-  ~(put by smp)
  ::X   ^-  [ship (set ship)]
  ::X   ?+  (clan:title who)  !!
  ::X     %king  [who (fall (~(get by smp) who) ~)]
  ::X     %duke  :-  par
  ::X            =+  sm=(fall (~(get by smp) par) ~)
  ::X            (~(put in sm) who)
  ::X   ==
  ::
  ::  contract deployment
  ::
  ~&  'Deploying ships...'
  =^  ships  this
    (do-deploy 'ships' ~)
  ~&  'Deploying polls...'
  =^  polls  this
    %+  do-deploy  'polls'
    ~[uint+1.209.600 uint+604.800]  ::TODO  decide on values
  ~&  'Deploying claims...'
  =^  claims  this
    %+  do-deploy  'claims'
    ~[address+ships]
  ~&  'Deploying constitution-ceremony...'
  =^  constit  this
    %+  do-deploy  'constitution-ceremony'
    :~  [%address 0x0]
        [%address ships]
        [%address polls]
        [%address claims]
    ==
  =.  constitution  constit
  ~&  'Transferring contract ownership...'
  =.  this
    %^  do  ships  50.000
    (transfer-ownership:dat constit)
  =.  this
    %^  do  polls  50.000
    (transfer-ownership:dat constit)
  ~&  'Deploying linear-star-release...'
  =^  linear-star-release  this
    %+  do-deploy  'linear-star-release'
    ~[address+ships]
  ::X ~&  'Deploying conditional-star-release...'
  ::X =^  conditional-star-release  this
  ::X   %+  do-deploy  'conditional-star-release'
  ::X   :~  [%address ships]
  ::X     ::
  ::X       :-  %array
  ::X       :~  [%bytes 32^`@`0x0]
  ::X           [%bytes 32^`@`0x2]  ::TODO  settle on value
  ::X           [%bytes 32^`@`0x3]  ::TODO  settle on value
  ::X       ==
  ::X     ::
  ::X       :-  %array  ::TODO  verify
  ::X       :~  [%uint 1.515.974.400]  ::  2018-01-15 00:00:00 UTC
  ::X           [%uint 1.547.510.400]  ::  2019-01-15 00:00:00 UTC
  ::X           [%uint 1.579.046.400]  ::  2020-01-15 00:00:00 UTC
  ::X       ==
  ::X     ::
  ::X       :-  %array  ::TODO  verify
  ::X       :~  [%uint 1.547.510.400]  ::  2019-01-15 00:00:00 UTC
  ::X           [%uint 1.579.046.400]  ::  2020-01-15 00:00:00 UTC
  ::X           [%uint 1.610.668.800]  ::  2021-01-15 00:00:00 UTC
  ::X       ==
  ::X   ==
  ~&  'Deploying censures...'
  =^  censures  this
    %+  do-deploy  'censures'
    ~[address+ships]
  ~&  'Deploying delegated-sending...'
  =^  delegated-sending  this
    %+  do-deploy  'delegated-sending'
    ~[address+ships]
  ~&  'Deploying constitution-resolver...'
  =^  constitution-resolver  this
    %+  do-deploy  'constitution-resolver'
    ~[address+ships]
  ::
  ::  tlon galaxy booting
  ::
  ::X ~&  ['Booting Tlon galaxies...' +(nonce)]
  ::X =/  galaxies  (sort tlon-gal order-shiplist)
  ::X |-
  ::X ?^  galaxies
  ::X   =.  this
  ::X     (create-ship [who ~ net]:i.galaxies)
  ::X   $(galaxies t.galaxies)
  ::
  ::  direct deeding
  ::
  ::X ~&  ['Directly deeding assets...' +(nonce)]
  ::X =/  stars  (sort ~(tap by star-map) order-shiplist)
  ::X |-
  ::X ?^  stars
  ::X   =*  star  p.i.stars
  ::X   ~&  [star=star nonce=nonce]
  ::X   =+  star-deed=(~(got by deed-map) star)
  ::X   =.  this
  ::X     (create-ship star ~ net.star-deed)
  ::X   ::
  ::X   =+  planets=(sort ~(tap in q.i.stars) lth)
  ::X   |-
  ::X   ?^  planets
  ::X     =*  planet  i.planets
  ::X     ~&  [planet=planet nonce=nonce]
  ::X     =+  plan-deed=(~(got by deed-map) planet)
  ::X     =.  this
  ::X       (create-ship planet ~ net.plan-deed)
  ::X     ::
  ::X     =.  this
  ::X       (send-ship planet [own manage voting spawn transfer]:plan-deed)
  ::X     $(planets t.planets)
  ::X   ::
  ::X   =.  this
  ::X     (send-ship star [own manage voting spawn transfer]:star-deed)
  ::X   ^$(stars t.stars)
  ::
  ::  linear release registration and deeding
  ::
  ~&  ['Registering linear release recipients...' +(nonce)]
  |-
  ?^  lin-rec
    =.  this
      %^  do  linear-star-release  350.000
      (register-linear:dat i.lin-rec)
    $(lin-rec t.lin-rec)
  ::
  ~&  ['Depositing linear release galaxies...' +(nonce)]
  =.  this
    (deposit-galaxies linear-star-release lin-gal)
  ::
  ::X ~&  ['Depositing linear release stars...' +(nonce)]
  ::X =.  this
  ::X   (deposit-stars linear-star-release lin-sar)
  ::
  ::  conditional release registration and deeding
  ::
  ::X ~&  ['Registering conditional release recipients...' +(nonce)]
  ::X |-
  ::X ?^  con-rec
  ::X   =.  this
  ::X     %^  do  conditional-star-release  350.000
  ::X     (register-conditional:dat i.con-rec)
  ::X   $(con-rec t.con-rec)
  ::
  ::X ~&  ['Depositing conditional release galaxies...' +(nonce)]
  ::X =.  this
  ::X   (deposit-galaxies conditional-star-release con-gal)
  ::
  ::X ~&  ['Depositing conditional release stars...' +(nonce)]
  ::X =.  this
  ::X   (deposit-stars conditional-star-release con-sar)
  ::
  ::  tlon galaxy sending
  ::
  ::X ~&  ['Sending Tlon galaxies...' +(nonce)]
  ::X =/  galaxies  (sort tlon-gal order-shiplist)
  ::X |-
  ::X ?^  galaxies
  ::X   =.  this
  ::X     (send-ship [who own manage voting spawn transfer]:i.galaxies)
  ::X   $(galaxies t.galaxies)
  ::
  ::  concluding ceremony
  ::
  ::X ~&  ['Deploying constitution-final...' +(nonce)]
  ::X =^  constit-final  this
  ::X   %+  do-deploy  'constitution-final'
  ::X   :~  [%address constit]
  ::X       [%address ships]
  ::X       [%address polls]
  ::X       [%address claims]
  ::X   ==
  ::X =.  this
  ::X   ::NOTE  currently included bytecode has on-upgrade ens functionality
  ::X   ::      stripped out to make this not fail despite 0x0 dns contract
  ::X   %^  do  constit  300.000
  ::X   (upgrade-to:dat constit-final)
  ::X ::
  ::X =.  this
  ::X   %^  do  constit-final  300.000
  ::X   (set-dns-domains:dat "urbit.org" "urbit.org" "urbit.org")
  ::
  complete
::
::  sign pre-generated transactions
++  sign
  |=  [won=@da in=path key=path]
  ^-  (list cord)
  =.  now  won
  ?>  ?=([@ @ @ *] key)
  =/  pkf  (get-file t.t.t.key)
  ?>  ?=(^ pkf)
  =/  pk  (rash i.pkf ;~(pfix (jest '0x') hex))
  =/  txs  .^((list transaction) %cx in)
  =/  enumerated
    =/  n  1
    |-  ^-  (list [@ud transaction])
    ?~  txs
      ~
    [[n i.txs] $(n +(n), txs t.txs)]
  %+  turn  enumerated
  |=  [n=@ud tx=transaction]
  ~?  =(0 (mod n 100))  [%signing n]
  (crip '0' 'x' ((x-co:co 0) (sign-transaction tx pk)))
::
::  create or spawn a ship, configure its spawn proxy and pubkeys
++  create-ship
  |=  $:  who=ship
          spawn=(unit address)
          keys=(unit [@ux @ux])
      ==
  ^+  this
  =+  wat=(clan:title who)
  =*  do-c  (cury (cury do constitution) 300.000)
  =.  this
    ?:  ?=(%czar wat)
      (do-c (create-galaxy:dat who))
    (do-c (spawn:dat who))
  =?  this  &(?=(^ spawn) !?=(%duke wat))
    (do-c (set-spawn-proxy:dat who u.spawn))
  =?  this  ?=(^ keys)
    (do-c (configure-keys:dat who u.keys))
  this
::
::  transfer a ship to a new owner, set a transfer proxy
++  send-ship
  |=  $:  who=ship
          own=address
          manage=(unit address)
          voting=(unit address)
          spawn=(unit address)
          transfer=(unit address)
      ==
  ^+  this
  =+  wat=(clan:title who)
  =*  do-c  (cury (cury do constitution) 300.000)
  =?  this  ?=(^ manage)
    (do-c (set-management-proxy:dat who u.manage))
  =?  this  &(?=(^ voting) ?=(%czar wat))
    (do-c (set-voting-proxy:dat who u.voting))
  =?  this  &(?=(^ spawn) !?=(%duke wat))
    (do-c (set-spawn-proxy:dat who u.spawn))
  =?  this  ?=(^ transfer)
    (do-c (set-transfer-proxy:dat who u.transfer))
  =.  this
    (do-c (transfer-ship:dat who own))
  this
::
::  deposit a whole galaxy into a star release contract
++  deposit-galaxies
  |=  [into=address galaxies=(list [gal=ship rights])]
  ^+  this
  =.  galaxies  (sort galaxies order-shiplist)
  |-
  ?~  galaxies  this
  ~&  [(lent galaxies) 'galaxies remaining' nonce]
  =*  galaxy  gal.i.galaxies
  ~&  `@p`galaxy
  =*  gal-deed  i.galaxies
  ::
  ::  create the galaxy, with spawn proxy set to the lockup contract
  =.  this
    ~|  [%locked-galaxy-needs-network-keys galaxy]
    ~!  net.gal-deed
    ?>  ?=(^ net.gal-deed)
    (create-ship galaxy `into net.gal-deed)
  ::
  ::  deposit all its stars
  =+  stars=(gulf 1 255)
  |-
  ?^  stars
    =.  this
      %^  do  into  350.000
      %-  deposit:dat
      [own.gal-deed (cat 3 galaxy i.stars)]
    $(stars t.stars)
  ::
  ::  send the galaxy to its owner, with spawn proxy at zero
  ::  because it can't spawn anymore
  =.  this
    (send-ship galaxy [own manage voting ?~(spawn `0x0 spawn) transfer]:gal-deed)
  ^$(galaxies t.galaxies)
::
::  deposit a list of stars
++  deposit-stars
  |=  [into=address stars=(list [who=ship recipient=address])]
  ^+  this
  =.  stars  (sort stars order-shiplist)
  =|  gals=(set ship)
  |-
  ?~  stars  this
  =*  star  who.i.stars
  =*  to  recipient.i.stars
  ::
  ::  if the parent galaxy hasn't made the target contracts
  ::  a spawn proxy yet, do so now
  =+  par=(^sein:title star)
  =?  this  !(~(has in gals) par)
    =.  gals  (~(put in gals) par)
    %^  do  constitution  300.000
    %+  set-spawn-proxy:dat  par
    into
  ::
  =.  this
    %^  do  into  550.000
    (deposit:dat to star)
  $(stars t.stars)
::
::  call data generation
::TODO  most of these should later be cleaned and go in ++constitution
::
++  dat
  |%
  ++  enc
    |*  cal=$-(* call-data)
    (cork cal encode-call)
  ::
  ++  create-galaxy           (enc create-galaxy:cal)
  ++  spawn                   (enc spawn:cal)
  ++  configure-keys          (enc configure-keys:cal)
  ++  set-spawn-proxy         (enc set-spawn-proxy:cal)
  ++  transfer-ship           (enc transfer-ship:cal)
  ++  set-management-proxy    (enc set-management-proxy:cal)
  ++  set-voting-proxy        (enc set-voting-proxy:cal)
  ++  set-transfer-proxy      (enc set-transfer-proxy:cal)
  ++  set-dns-domains         (enc set-dns-domains:cal)
  ++  upgrade-to              (enc upgrade-to:cal)
  ++  transfer-ownership      (enc transfer-ownership:cal)
  ++  register-linear         (enc register-linear:cal)
  ++  register-conditional    (enc register-conditional:cal)
  ++  deposit                 (enc deposit:cal)
  --
::
++  cal
  |%
  ++  create-galaxy
    |=  gal=ship
    ^-  call-data
    ?>  =(%czar (clan:title gal))
    :-  'createGalaxy(uint8,address)'
    ^-  (list data)
    :~  [%uint `@`gal]
        [%address addr]
    ==
  ::
  ++  spawn
    |=  who=ship
    ^-  call-data
    ?>  ?=(?(%king %duke) (clan:title who))
    :-  'spawn(uint32,address)'
    :~  [%uint `@`who]
        [%address addr]
    ==
  ::
  ++  configure-keys
    |=  [who=ship crypt=@ auth=@]
    ?>  (lte (met 3 crypt) 32)
    ?>  (lte (met 3 auth) 32)
    :-  'configureKeys(uint32,bytes32,bytes32,uint32,bool)'
    :~  [%uint `@`who]
        [%bytes-n 32^crypt]
        [%bytes-n 32^auth]
        [%uint 1]
        [%bool |]
    ==
  ::
  ++  set-management-proxy
    |=  [who=ship proxy=address]
    ^-  call-data
    :-  'setManagementProxy(uint32,address)'
    :~  [%uint `@`who]
        [%address proxy]
    ==
  ::
  ++  set-voting-proxy
    |=  [who=ship proxy=address]
    ^-  call-data
    :-  'setVotingProxy(uint8,address)'
    :~  [%uint `@`who]
        [%address proxy]
    ==
  ::
  ++  set-spawn-proxy
    |=  [who=ship proxy=address]
    ^-  call-data
    :-  'setSpawnProxy(uint16,address)'
    :~  [%uint `@`who]
        [%address proxy]
    ==
  ::
  ++  transfer-ship
    |=  [who=ship to=address]
    ^-  call-data
    :-  'transferShip(uint32,address,bool)'
    :~  [%uint `@`who]
        [%address to]
        [%bool |]
    ==
  ::
  ++  set-transfer-proxy
    |=  [who=ship proxy=address]
    ^-  call-data
    :-  'setTransferProxy(uint32,address)'
    :~  [%uint `@`who]
        [%address proxy]
    ==
  ::
  ++  set-dns-domains
    |=  [pri=tape sec=tape ter=tape]
    ^-  call-data
    :-  'setDnsDomains(string,string,string)'
    :~  [%string pri]
        [%string sec]
        [%string ter]
    ==
  ::
  ++  upgrade-to
    |=  to=address
    ^-  call-data
    :-  'upgradeTo(address)'
    :~  [%address to]
    ==
  ::
  ::
  ++  transfer-ownership  ::  of contract
    |=  to=address
    ^-  call-data
    :-  'transferOwnership(address)'
    :~  [%address to]
    ==
  ::
  ::
  ++  register-linear
    |=  $:  to=address
            windup=@ud
            stars=@ud
            rate=@ud
            rate-unit=@ud
        ==
    ^-  call-data
    :-  'register(address,uint256,uint16,uint16,uint256)'
    :~  [%address to]
        [%uint windup]
        [%uint stars]
        [%uint rate]
        [%uint rate-unit]
    ==
  ::
  ++  register-conditional
    |=  $:  to=address
            b1=@ud
            b2=@ud
            b3=@ud
            rate=@ud
            rate-unit=@ud
        ==
    ^-  call-data
    :-  'register(address,uint16[],uint16,uint256)'
    :~  [%address to]
        [%array ~[uint+b1 uint+b2 uint+b3]]
        [%uint rate]
        [%uint rate-unit]
    ==
  ::
  ++  deposit
    |=  [to=address star=ship]
    ^-  call-data
    :-  'deposit(address,uint16)'
    :~  [%address to]
        [%uint `@`star]
    ==
  --
--
