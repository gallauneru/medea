$title medea

* ==============================================================================
* COMMAND LINE OPTIONS
* ------------------------------------------------------------------------------
* command-line option --PROJECT
* includes .gms-file medea_%PROJECT%.gms right before model-statement, allowing
* for custom modifications to medea
* '--PROJECT=test' is not admissible as it is reserved for unit testing
* ------------------------------------------------------------------------------
* command-line option --SCENARIO
* tries to read data from .gdx-file 'MEDEA_%scenario%_data.gdx'
* if this does not exit, fall back to default 'medea_main_data.gdx'
* ------------------------------------------------------------------------------
* command-line option --NORAGUROBI
* NORAGUROBI no: use default solver on local machine (recommended)
* NORAGUROBI yes: use gurobi solver on nora (only in boku lan)
* ------------------------------------------------------------------------------
* command-line option --SYNGAS
* SYNGAS no: use default fuels for power generation
* SYNGAS yes: allow for use of synthetic gas in natural gas-fired units
* ==============================================================================
$if not set NORAGUROBI $set NORAGUROBI no
$if not set SYNGAS $set SYNGAS yes
* ==============================================================================

* enable end.of.line-comments with '#'
$onEoLCom
$EoLCom #

* ==============================================================================
* SYMBOL DECLARATIONS
* ------------------------------------------------------------------------------
Sets
         e                       energy carriers
         i                       dispatchable energy generation technologies
         h(i)                    power-to-heat technologies
         j(i)                    combined heat and power (CHP) generation technologies
         k                       energy storage technologies
         l                       corners of feasible operating regions of CHPs
         m(e)                    energy carriers for end use
         n                       intermittent electricity generators
         t                       time periods (hours)
         z                       market zones
;
alias(z,zz);
alias(e,ee);

* ------------------------------------------------------------------------------
Parameters
         CAPITALCOST_G(i)        specific annualized capital cost of dispatchable generators [EUR per MW]
         CAPITALCOST_R(z,n)      specific annualized capital cost of intermittent generators [EUR per MW]
         CAPITALCOST_S(z,k)      specific annualized capital cost of storage power (in and out) [EUR per MW]
         CAPITALCOST_V(z,k)      specific annualized capital cost of storage volume [EUR per MWh]
         CAPITALCOST_X(z)        specific annualized capital cost of electricity transmission [EUR per MW]
         CO2_INTENSITY(e)        CO2 intensitiy of fuels burned [t CO2 per MWh_th]
         DEMAND(z,t,m)           energy demand [GW]
         DISTANCE(z,zz)          distance between centers of gravity of market areas [km]
         EFFICIENCY_G(i,e,ee)    generation efficiency of dispatchable power plants [MWh_el per MWh_th]
         EFFICIENCY_S_OUT(z,k)   generation efficiency of storages
         EFFICIENCY_S_IN(z,k)    storing-in efficiency of storages
         FEASIBLE_INPUT(i,l,e)   relative fuel requirement at corners of feasible operating region
         FEASIBLE_OUTPUT(i,l,m)  relative energy production at corners of feasible operating region
         GEN_PROFILE(z,t,n)      generation profile of intermittent sources
         INFLOWS(z,t,k)          energy content of (exogenous) inflows to storages [GW]
         INITIAL_CAP_G(z,i)      initial installed capacity of dispatchable generators [GW]
         INITIAL_CAP_R(z,n)      initial installed capacity of intermittent generators [GW]
         INITIAL_CAP_S_OUT(z,k)  initial installed capacity to store-out [GW]
         INITIAL_CAP_S_IN(z,k)   intial installed capacity to store-in [GW]
         INITIAL_CAP_V(z,k)      initial installed storage volume [GWh]
         INITIAL_CAP_X(z,zz)     initial installed transmission capacity [GW]
         LAMBDA                  load scaling factor for system service requirement
         MAP_STORAGE_CARRIERS(k,e) mapping of energy carriers to storage units
         OM_COST_G_QFIX(i)       quasi-fixed operation and maintenance cost [EUR per MW]
         OM_COST_G_VAR(i)        variable operation and maintenance cost [EUR per MWh]
         OM_COST_R_QFIX(z,n)     quasi-fixed operation and maintenance cost [EUR per MW]
         OM_COST_R_VAR(z,n)      variable operation and maintenance cost [EUR per MWh]
         PEAK_LOAD(z)            maximum electricity demand [GW]
         PEAK_PROFILE(z,n)       maximum relative generation from intermittent sources
         PLANT_FUELS(i,e)        maps energy carriers to conversion units - used to tighten model formulation
         PLANT_PRODUCTS(i,m)     maps products to conversion units
         PRICE_CO2(z,t)          CO2 price [EUR per t CO2]
         PRICE_FUEL(z,t,e)       fuel price [EUR per MWh]
         PRICE_TRADE(e)          price of hydrogen and syngas [EUR per MWh]
         SIGMA                   intermittent generation scaling factor for system service requirement
         VALUE_NSE(z)            value of non-served energy [EUR]
         SWITCH_INVEST_THERM     abc
         SWITCH_INVEST_ITM       abc
         SWITCH_INVEST_STORAGE   abc
         SWITCH_INVEST_ATC       cdf
;

* ------------------------------------------------------------------------------
* load data
$if %PROJECT% == test $gdxin medea_testing_period
$if %PROJECT% == test $load t
$if %PROJECT% == test $gdxin

$if NOT exist MEDEA_%scenario%_data.gdx  $gdxin medea_main_data_lysr
$if     exist MEDEA_%scenario%_data.gdx  $gdxin medea_%scenario%_data
$if NOT %PROJECT% == test $load t
$load    e i h j k l m n z
$load    CAPITALCOST_R CAPITALCOST_G CAPITALCOST_S CAPITALCOST_V CAPITALCOST_X
$load    CO2_INTENSITY DEMAND DISTANCE EFFICIENCY_G EFFICIENCY_S_OUT
$load    EFFICIENCY_S_IN FEASIBLE_INPUT FEASIBLE_OUTPUT GEN_PROFILE INFLOWS
$load    INITIAL_CAP_G INITIAL_CAP_R INITIAL_CAP_S_OUT INITIAL_CAP_S_IN
$load    INITIAL_CAP_V INITIAL_CAP_X LAMBDA MAP_STORAGE_CARRIERS OM_COST_G_QFIX
$load    OM_COST_G_VAR OM_COST_R_QFIX OM_COST_R_VAR PRICE_CO2
$load    PEAK_LOAD PEAK_PROFILE PRICE_FUEL SIGMA VALUE_NSE
$load    SWITCH_INVEST_THERM SWITCH_INVEST_ITM SWITCH_INVEST_STORAGE
$load    SWITCH_INVEST_ATC
$gdxin

PLANT_FUELS(i,e)$(sum(m,EFFICIENCY_G(i,m,e))) = yes;
PLANT_PRODUCTS(i,m)$(sum(e,EFFICIENCY_G(i,m,e))) = yes;
PLANT_PRODUCTS(i,'heat')$(j(i)) = yes;
display PLANT_PRODUCTS;

* ------------------------------------------------------------------------------
* enable the use of synthetic gas in natural gas-fired plant
$if %SYNGAS% == yes PLANT_FUELS(i,'Syngas')$PLANT_FUELS(i,'Gas') = yes;
$if %SYNGAS% == yes EFFICIENCY_G(i, 'Power', 'Syngas') = EFFICIENCY_G(i, 'Power', 'Gas');
$if %SYNGAS% == yes FEASIBLE_INPUT(i,l,'Syngas') = FEASIBLE_INPUT(i,l,'Gas');

PRICE_TRADE('Hydrogen') = 35;
PRICE_TRADE('Syngas') = 40;

* ------------------------------------------------------------------------------
Variables
         cost_system             total system cost [kEUR]
         x(z,zz,t)               (net) commercial electricity exchange between market zones [GW]  # exports are positive - imports negative
         fuel_trade(z,t,e)       sales and purchases of hydrogen and syngas # positive if purchases
         cost_trade(z)           cost of purchasing or selling hydrogen and syngas
;

Positive Variables
         cost_fuel(z,t,i)        total cost of fuel used for energy generation [kEUR]
         cost_co2(z,t,i)         total cost of CO2 emissions [kEUR]
         cost_om_g(z,i)          total operation and maintenance cost of dispatchables [kEUR]
         cost_om_r(z,n)          total operation and maintenance cost of intermittents[kEUR]
         cost_zonal(z)           total zonal system cost [kEUR]
         cost_nse(z)             total cost of non-served energy [kEUR]
         cost_invest_g(z)        total investment cost for dispatchable generators [kEUR]
         cost_invest_r(z)        total investment cost for intermittent generators [kEUR]
         cost_invest_sv(z)       total investment cost for storages [kEUR]
         cost_invest_x(z)        total investment cost for transmission capacity [kEUR]
         emission_co2(z,t,i)     bookkeeping of total co2 emissions [kt] # or rather [t]?
         b(z,t,i,e)              fuel used for energy conversion [GWh]
         add_g(z,i)              dispatchable generation capacity added [GW]
         add_r(z,n)              intermittent generation capacity added [GW]
         add_s(z,k)              storage capacity (in and out) added [GW]
         add_v(z,k)              storage volume added [GWh]
         add_x(z,zz)             transmission capacity added [GW]
         deco_g(z,i)             dispatchable generation capacity decommissioned [GW]
         deco_r(z,n)             intermittent generation capacity decommissioned [GW]
*         deco_s(z,k)             storage capacity (in and out) decommissioned [GW]
*         deco_v(z,k)             storage volume decommissioned [GWh]
*         deco_x(z,zz)            transmission capacity decommissioned [GW]
         g(z,t,i,e,ee)           energy conversion by dispatchable units [GW]
         r(z,t,n)                bookkeeping of electricity generation by intermittent generators [GW]
         s_in(z,t,k,e)           energy stored-in (flow) [GW]
         s_out(z,t,k,e)          energy stored-out (flow) [GW]
         v(z,t,k)                energy storage level (stock) [GWh]
         q_curtail(z,t)          curtailed electricity [GW]
         q_nse(z,t,m)            non-served energy [GW]
         w(z,t,i,l,e)            feasible operating region weight
;
* ==============================================================================

* ==============================================================================
* EQUATION DECLARATION
* equation naming:
* bal: balance - equality constraint, decision variables on both sides
* acn: accounting - equality constraint, decision variable on one side, bookkeeping variable on other
* uplim: upper limit - inequality constraint (less than)
* lolim: lower limit - inequality constraint (greater than)
* ------------------------------------------------------------------------------
Equations
objective, bal_zone,
bal_fuel, bal_co2, bal_om_g, bal_om_r, bal_inv_g, bal_inv_r, bal_inv_sv, bal_inv_x, bal_nse, bal_trade,
bal_el, bal_ht, bal_h2, bal_ch4,
uplim_g, lolim_b,
bal_w_chp, uplim_g_chp, lolim_b_chp,
acn_itm,
uplim_store_in, uplim_store_out, uplim_store_vol, bal_store, lolim_add_v,
acn_co2,
uplim_transmission, lolim_transmission, bal_transmission, bal_add_x,
uplim_deco_g, uplim_deco_r,
lolim_ancservices,
uplim_curtail
;
* ==============================================================================


* ==============================================================================
* MODEL FORMULATION
* ------------------------------------------------------------------------------
* SYSTEM COST and COST BALANCES

objective..
                 cost_system
                 =E=
                 sum(z, cost_zonal(z))
                 ;
bal_zone(z)..
                 cost_zonal(z)
                 =E=
                 sum((t,i), cost_fuel(z,t,i))
                 + sum((t,i), cost_co2(z,t,i))
                 + sum(i, cost_om_g(z,i))
                 + sum(n, cost_om_r(z,n))
                 + cost_invest_g(z)
                 + cost_invest_r(z)
                 + cost_invest_sv(z)
                 + cost_invest_x(z)
                 + cost_nse(z)
                 + cost_trade(z)
                 ;
bal_fuel(z,t,i)..
                 cost_fuel(z,t,i)
                 =E=
                 sum(e$(PLANT_FUELS(i,e) ), PRICE_FUEL(z,t,e) * b(z,t,i,e) )
                 ;
bal_co2(z,t,i)..
                 cost_co2(z,t,i)
                 =E=
                 PRICE_CO2(z,t) * emission_co2(z,t,i)
                 ;
bal_om_g(z,i)..
                 cost_om_g(z,i)
                 =E=
                 OM_COST_G_QFIX(i) * (INITIAL_CAP_G(z,i) + add_g(z,i) - deco_g(z,i) )
                 + sum((t,m,e)$(PLANT_FUELS(i,e) ), OM_COST_G_VAR(i) * g(z,t,i,m,e) )
                 ;
bal_om_r(z,n)..
                 cost_om_r(z,n)
                 =E=
                 OM_COST_R_QFIX(z,n) * (INITIAL_CAP_R(z,n) + add_r(z,n) - deco_r(z,n) )
                 + sum((t,m), OM_COST_R_VAR(z,n) * r(z,t,n) )
                 ;
bal_inv_g(z)..
                 cost_invest_g(z)
                 =E=
                 sum(i, CAPITALCOST_G(i) * add_g(z,i) )
                 ;
bal_inv_r(z)..
                 cost_invest_r(z)
                 =E=
                 sum(n, CAPITALCOST_R(z,n) * add_r(z,n) )
                 ;
bal_inv_sv(z)..
                 cost_invest_sv(z)
                 =E=
                 sum(k, CAPITALCOST_S(z,k) * add_s(z,k)
                 + CAPITALCOST_V(z,k) * add_v(z,k) )
                 ;
bal_inv_x(z)..
                 cost_invest_x(z)
                 =E=
                 0.5 * sum(zz, CAPITALCOST_X(z) * DISTANCE(z,zz) * add_x(z,zz) )
                 ;
bal_nse(z)..
                 cost_nse(z)
                 =E=
                 sum((t,m), VALUE_NSE(z) * q_nse(z,t,m) )
                 ;
bal_trade(z)..
                 cost_trade(z)
                 =E=
                 sum((t,e), PRICE_TRADE(e) * fuel_trade(z,t,e) )
                 ;
* ------------------------------------------------------------------------------
* MARKET CLEARING

bal_el(z,t)..
                 sum((i,e)$(PLANT_FUELS(i,e) ), g(z,t,i,'Power',e) )
                 + sum(n, r(z,t,n) )
                 + sum(k, s_out(z,t,k,'Power') )
                 - q_curtail(z,t)
                 =E=
                 DEMAND(z,t,'Power')
                 + sum(i, b(z,t,i,'Power') )
                 + sum(k, s_in(z,t,k,'Power') )
                 + sum(zz, x(z,zz,t) )
                 - q_nse(z,t,'Power')
                 ;

bal_ht(z,t)..
                 sum((i,e)$(PLANT_FUELS(i,e) ), g(z,t,i,'Heat',e) )
                 + sum(k, s_out(z,t,k,'Heat') )
                 =E=
                 DEMAND(z,t,'Heat')
                 + sum(k, s_in(z,t,k,'Heat'))
                 - q_nse(z,t,'Heat')
                 ;
bal_h2(z,t)..
                 g(z,t,'Elyser','Hydrogen','Power')
                 + s_out(z,t,'str_hydrogn','Hydrogen')
                 + fuel_trade(z,t,'Hydrogen')
                 =E=
                 b(z,t,'Methn','Hydrogen')
                 + s_in(z,t,'str_hydrogn','Hydrogen')
                 ;
bal_ch4(z,t)..
                 g(z,t,'Methn','Syngas','Hydrogen')
                 + s_out(z,t,'str_syng','Syngas')
                 + fuel_trade(z,t,'Syngas')
                 =E=
                 sum(i, b(z,t,i,'Syngas'))
                 + s_in(z,t,'str_syng','Syngas')
                 ;
* ------------------------------------------------------------------------------
* CONVENTIONAL ENERGY CONVERSION
* set efficiency for electricity-only gas plants

uplim_g(z,t,i,m)$(PLANT_PRODUCTS(i,m))..
                 sum(e$(EFFICIENCY_G(i,m,e)), g(z,t,i,m,e) )
                 =L=
                 INITIAL_CAP_G(z,i) + add_g(z,i) - deco_g(z,i)
                 ;
lolim_b(z,t,i,m,e)$(EFFICIENCY_G(i,m,e) AND NOT j(i))..
                 g(z,t,i,m,e)
                 =E=
                 EFFICIENCY_G(i,m,e) * b(z,t,i,e)
                 ;
b.UP(z,t,i,e)$(NOT PLANT_FUELS(i,e)) = 0;
g.UP(z,t,i,m,e)$(NOT PLANT_PRODUCTS(i,m)) = 0;
* ------------------------------------------------------------------------------
* CO-GENERATION OF HEAT AND ELECTRICITY

* set kennlinienfeld for gas chps

bal_w_chp(z,t,i)$(j(i))..
                 sum((l,e)$(PLANT_FUELS(i,e) ), w(z,t,i,l,e))
                 =L=
                 INITIAL_CAP_G(z,i) + add_g(z,i) - deco_g(z,i)
                 ;
uplim_g_chp(z,t,i,m,e)$(PLANT_FUELS(i,e) AND j(i))..
                 g(z,t,i,m,e)
                 =E=
                 sum(l$(PLANT_FUELS(i,e) ), FEASIBLE_OUTPUT(i,l,m) * w(z,t,i,l,e) )
                 ;
lolim_b_chp(z,t,i,e)$(PLANT_FUELS(i,e) AND j(i))..
                 b(z,t,i,e)
                 =E=
                 sum(l$(PLANT_FUELS(i,e) ), FEASIBLE_INPUT(i,l,e) * w(z,t,i,l,e) )
                 ;
w.UP(z,t,i,l,e)$(NOT FEASIBLE_INPUT(i,l,e)) = 0;
* ------------------------------------------------------------------------------
* INTERMITTENT ELECTRICITY GENERATION

acn_itm(z,t,n)..
                 r(z,t,n)
                 =E=
                 GEN_PROFILE(z,t,n) * (INITIAL_CAP_R(z,n) + add_r(z,n) - deco_r(z,n) )
                 ;
* ------------------------------------------------------------------------------
* PRODUCT STORAGE
* energy products 'el', 'ht', 'h2', and 'ch4' are stored in and out
* conversion does not happen at the level of storage (but at the level of conversion)
* storage is strictly measured in energy units

* > add 'h2', 'ch4' to products-set -- DONE
* > !!! MUST MAP k to m in parameter STORAGE_PRODUCTS(k,m) !!!

* STEP 1: convert electricity to h2 with i = electrolyser
* STEP 2: store h2 with k = hydrogen_storage
* STEP 3: sell h2 or convert to ch4 with i = methanation_unit
* STEP 4: store ch4 with k = meth_storage
* STEP 5: allow for sales of ch4 or use as syngas-input for gas-fired units
* STEP 5: subtract revenues from sales to system cost

* >> introduce hydrogen balance - DONE
* >> introduce syngas balance - DONE
* >> allow storage of all kinds of products -- DONE
* >> allow conversion of el to h2 and of h2 to ch4/syngas -- DONE
* >> add cost/revenue of fuel_trade to system cost
* >> introduce technologies and parameters for conversion from el to h2 and from h2 to ch4


uplim_store_out(z,t,k,m)$(MAP_STORAGE_CARRIERS(k,m))..
                 s_out(z,t,k,m)
                 =L=
                 INITIAL_CAP_S_OUT(z,k) + add_s(z,k)
                 ;
s_out.UP(z,t,k,e)$(NOT MAP_STORAGE_CARRIERS(k,e)) = 0;

uplim_store_in(z,t,k,m)$(MAP_STORAGE_CARRIERS(k,m))..
                 s_in(z,t,k,m)
                 =L=
                 INITIAL_CAP_S_IN(z,k) + add_s(z,k)
                 ;
s_in.UP(z,t,k,e)$(NOT MAP_STORAGE_CARRIERS(k,e)) = 0;

bal_store(z,t,k)$(ord(t) > 1 AND EFFICIENCY_S_OUT(z,k))..
                 v(z,t,k)
                 =E=
                 INFLOWS(z,t,k)
                 + sum(m$(MAP_STORAGE_CARRIERS(k,m)), EFFICIENCY_S_IN(z,k) * s_in(z,t,k,m))
                 - sum(m$(MAP_STORAGE_CARRIERS(k,m)), (1 / EFFICIENCY_S_OUT(z,k))  * s_out(z,t,k,m))
                 + v(z,t-1,k)
                 ;
v.UP(z,t,k)$(NOT EFFICIENCY_S_OUT(z,k)) = 0;

uplim_store_vol(z,t,k)..
                 v(z,t,k)
                 =L=
                 INITIAL_CAP_V(z,k) + add_v(z,k)
                 ;
lolim_add_v(z,k)..
                 add_v(z,k)
                 =G=
                 add_s(z,k)
                 ;

* ------------------------------------------------------------------------------
* CO2 ACCOUNTING

acn_co2(z,t,i)..
                 emission_co2(z,t,i)
                 =E=
                 sum(e$(CO2_INTENSITY(e) AND PLANT_FUELS(i,e)), CO2_INTENSITY(e) * b(z,t,i,e) )
                 ;
* ------------------------------------------------------------------------------
* INTERZONAL ELECTRICITY EXCHANGE

uplim_transmission(z,zz,t)..
                 x(z,zz,t)
                 =L=
                 INITIAL_CAP_X(z,zz) + add_x(z,zz)
                 ;
lolim_transmission(z,zz,t)..
                 x(z,zz,t)
                 =G=
                 - (INITIAL_CAP_X(z,zz) + add_x(z,zz) )
                 ;
bal_transmission(z,zz,t)..
                 x(z,zz,t)
                 =E=
                 - x(zz,z,t)
                 ;
bal_add_x(z,zz)..
                 add_x(z,zz)
                 =E=
                 add_x(zz,z)
                 ;
x.FX(z,zz,t)$(not INITIAL_CAP_X(z,zz))   = 0;
x.FX(zz,z,t)$(not INITIAL_CAP_X(zz,z))   = 0;
* ------------------------------------------------------------------------------
* DECOMMISSIONING

uplim_deco_g(z,i)..
                 deco_g(z,i)
                 =L=
                 INITIAL_CAP_G(z,i) + add_g(z,i)
                 ;
uplim_deco_r(z,n)..
                 deco_r(z,n)
                 =L=
                 INITIAL_CAP_R(z,n) + add_r(z,n)
                 ;
* ------------------------------------------------------------------------------
* ANCILLARY SERVICES

lolim_ancservices(z,t)..
                 sum((i,e)$(PLANT_FUELS(i,e) ), g(z,t,i,'Power',e) )
                 + r(z,t,'ror')
                 + sum((k,m), s_out(z,t,k,m) + s_in(z,t,k,m) )
                 =G=
                 LAMBDA * PEAK_LOAD(z)
                 + SIGMA * sum(n$(NOT SAMEAS(n,'ror')), PEAK_PROFILE(z,n) * (INITIAL_CAP_R(z,n) + add_r(z,n) ) )
                 ;
* ------------------------------------------------------------------------------
* CURTAILMENT

uplim_curtail(z,t)..
                 q_curtail(z,t)
                 =L=
                 sum(n$(NOT SAMEAS(n,'ror')), r(z,t,n) )
                 ;

* ------------------------------------------------------------------------------
* INVESTMENT SWITCHES FOR THE LONG AND THE SHORT RUN

add_g.UP(z,i) =  SWITCH_INVEST_THERM;
deco_g.UP(z,i) = SWITCH_INVEST_THERM;
add_r.UP(z,n) =  SWITCH_INVEST_ITM(z, n);
add_s.UP(z,k) =  SWITCH_INVEST_STORAGE(z, k);
add_v.UP(z,k) =  SWITCH_INVEST_STORAGE(z, k);
add_x.UP(z,zz) = 5 * SWITCH_INVEST_ATC(z,zz) * INITIAL_CAP_X(z,zz);
* ==============================================================================

fuel_trade.FX(z,t,e) = 0;


* ==============================================================================
* project control
* ------------------------------------------------------------------------------
$if set PROJECT $include medea_%PROJECT%.gms
* ==============================================================================

model medea / all /;

options
reslim = 54000,
threads = 8,
optCR = 0.01,
BRatio = 1
;

* ==============================================================================
* solve-settings control
* ------------------------------------------------------------------------------
$if %NORAGUROBI% == yes $include solve_with_noragurobi.gms
* ==============================================================================

solve medea using LP minimizing cost_system;


* ==============================================================================
* REPORTING

* ------------------------------------------------------------------------------
* solve details
scalars modelStat, solveStat;
modelStat = medea.modelstat;
solveStat = medea.solvestat;

* ------------------------------------------------------------------------------
* ex post renewables share
parameter
REN_SHARE(z),
ANN_G_BIOMASS(z),
ANN_G_SYNGAS(Z),
ANN_R(z),
ANN_EL_CONS(z);

REN_SHARE(z) =   (sum((t,n), r.L(z,t,n) )
                 + sum((t,k,e), s_out.L(z,t,k,e) )
                 - sum((t,k,e), s_in.L(z,t,k,e) )
                 + sum((t,i), g.L(z,t,i,'Power','Biomass') )
                 + sum((t,i), g.L(z,t,i,'Power','Syngas') ) )
                 / sum(t, DEMAND(z,t,'Power') )
                 ;

ANN_R(z) = sum((t,n), r.L(z,t,n) );
ANN_G_BIOMASS(z) = sum((t,i), g.L(z,t,i,'Power','Biomass') );
ANN_G_SYNGAS(Z) = sum((t,i), g.L(z,t,i,'Power','Syngas') );
ANN_EL_CONS(z) = sum(t, DEMAND(z,t,'Power') );

display REN_SHARE, ANN_G_BIOMASS, ANN_G_SYNGAS, ANN_R, ANN_EL_CONS;

* ------------------------------------------------------------------------------
* summary of exogenous parameters
parameters
ANNUAL_CONSUMPTION(z,m),
FULL_LOAD_HOURS(z,n),
AVG_PRICE(z,e),
AVG_PRICE_CO2(z);

ANNUAL_CONSUMPTION(z,m) = sum(t, DEMAND(z,t,m));
FULL_LOAD_HOURS(z,n) = sum(t, GEN_PROFILE(z,t,n));
AVG_PRICE(z,e) = sum(t, PRICE_FUEL(z,t,e)) / card(t);
AVG_PRICE_CO2(z) = sum(t, PRICE_CO2(z,t)) / card(t);

* ------------------------------------------------------------------------------
* annual system operation
parameter
annual_g(z,m),
annual_g_by_tec(z,i,m,e),
annual_s_in(z),
annual_s_out(z),
annual_x(z),
annual_b(z,e),
annual_co2(z),
annual_curtail(z);

annual_g(z,m) = sum((t,i,e), g.L(z, t, i, m, e));
annual_g_by_tec(z,i,m,e) = sum(t, g.L(z, t, i, m, e));
annual_s_in(z) = sum((t,k,e), s_in.L(z,t,k,e));
annual_s_out(z) = sum((t,k,e), s_out.L(z,t,k,e));
annual_x(zz) = sum(t, x.L('AT',zz,t));
annual_b(z,e) = sum((t,i), b.L(z,t,i,e));
annual_co2(z) = sum((t,i), emission_co2.L(z,t,i));
annual_curtail(z) = sum(t, q_curtail.L(z,t));

display annual_b, annual_s_in, annual_s_out;

* ------------------------------------------------------------------------------
* annual monetary values
parameters
annual_value_g(z,m),
annual_value_g_by_tec(z,i,m),
annual_value_s_in(z),
annual_value_s_out(z),
annual_value_x(z,zz),
annual_value_curtail(z);

annual_value_g(z,m) = sum((t,i,e), bal_el.M(z,t) * g.L(z,t,i,m,e));
annual_value_g_by_tec(z,i,m) = sum((t,e), bal_el.M(z,t) * g.L(z,t,i,m,e));
annual_value_s_in(z) = sum((t,k,e), bal_el.M(z,t) * s_in.L(z,t,k,e));
annual_value_s_out(z) = sum((t,k,e), bal_el.M(z,t) * s_out.L(z,t,k,e));
annual_value_x(z,zz) = sum(t, bal_el.M(z,t) * x.L(z,zz,t));
annual_value_curtail(z) = sum(t, bal_el.M(z,t) * q_curtail.L(z,t));

* ------------------------------------------------------------------------------
* annual prices, cost, producer surplus
parameter
annual_price_el(z),
annual_price_ht(z),
annual_cost_g(z,i),
annual_revenue_g(z,i),
annual_profit_g(z,i),
annual_surplus_g(z,i),
annual_profit_s(z,k),
annual_profit_r(z,n),
annual_surplus_s(z,k),
annual_surplus_r(z,n),
producer_surplus(z);

annual_price_el(z) = sum(t, bal_el.M(z,t))/card(t);
annual_price_ht(z) = sum(t, bal_ht.M(z,t))/card(t);

annual_cost_g(z,i) = sum(t, cost_fuel.L(z,t,i) + cost_co2.L(z,t,i) )
                     + cost_om_g.L(z,i);

annual_revenue_g(z,i) = sum((t,e), bal_el.M(z,t) * g.L(z,t,i,'Power',e)
                             + bal_ht.M(z,t) * g.L(z,t,i,'Heat',e) );
annual_profit_g(z,i) = annual_revenue_g(z,i) - annual_cost_g(z,i);
annual_surplus_g(z,i) = annual_revenue_g(z,i)
                         - sum(t, cost_fuel.L(z,t,i) + cost_co2.L(z,t,i) )
                         - sum((t,m,e), OM_COST_G_VAR(i) * g.L(z,t,i,m,e) );

annual_profit_s(z,k) = sum((t,e),
                         bal_el.M(z,t) * s_out.L(z,t,k,e)
                         - bal_el.M(z,t) * s_in.L(z,t,k,e)
                         );

annual_profit_r(z,n) = sum(t, bal_el.M(z,t) * r.L(z,t,n) )
                         - OM_COST_R_QFIX(z,n) * (INITIAL_CAP_R(z,n) + add_r.L(z,n) - deco_r.L(z,n) )
                         - sum(t, OM_COST_R_VAR(z,n) * r.L(z,t,n) );

producer_surplus(z) =    sum(i, annual_surplus_g(z,i))
                         + sum(k, annual_profit_s(z,k))
                         + sum((t,n), bal_el.M(z,t) * r.L(z,t,n))
                         - sum((t,n), OM_COST_R_VAR(z,n) * r.L(z,t,n) )
                         ;

* ------------------------------------------------------------------------------
* hourly prices
parameter
hourly_price_el(z,t),
hourly_price_ht(z,t),
hourly_price_system_services(z,t)
;

hourly_price_el(z,t) = bal_el.M(z,t);
hourly_price_ht(z,t) = bal_ht.M(z,t);
hourly_price_system_services(z,t) = lolim_ancservices.M(z,t);
* ==============================================================================


* ==============================================================================
* THE END
* ==============================================================================
* this line intentionally left blank
