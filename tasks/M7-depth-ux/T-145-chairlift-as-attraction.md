# T-145: Svævebane som attraktion – kører kun ved brug

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-091, T-144

## Mål
Brugerfeedback: svævebanen skal være en attraktion, som gæster vælger at køre i for oplevelsens skyld (ud over at være transport), og gondolerne må kun køre, når nogen bruger den. T-144's tomgangskørsel i `ParkView._transport_leg` fjernes.

## Acceptkriterier
- [x] Gæster vælger svævebanen som forlystelse (excitement/rating fra data, kø, billet) og kører til den anden station; den virker stadig som transport
- [x] Ingen tomgangskørsel: gondoler bevæger sig kun med passagerer
- [x] Tests (sim: gæster bruger den uden genvejsfordel; view: står stille uden passagerer) + balance kørt

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerfeedback
- 2026-10-16 – simulation: `ParkSim._choose_goal` medtager nu transport-attraktioner i forlystelsesvalget (vægt = excitement fra data, monorail.json har allerede excitement 15 / billet 2 – ingen dataændring). Gæsten går til indgangen, betaler og står i kø som ved en forlystelse; ved turens slut (`_on_ride_finished`, transport_id < 0) flyttes hun til den anden stations indgang (`_exit_at_other_station`), får visit-glæde og rides_left -= 1. Genvejsfunktionen (`_board_transport`/`_finish_transport`) er uændret. Bridge: tomgangspendulet fra T-144 fjernet i `ParkView._transport_leg` (idle_t/idle_wait slettet); kabinen holder ved sidste station, til sim'en kører en tur. Tests: `test_transport.test_guests_ride_transport_as_attraction` (parallel sti, ingen genvejsfordel → gæster rider og stiger af ved endestationen), `test_track_view.test_transport_cabin_still_without_riders` (erstatter idles-testen). test.sh 372/0, integration OK, balance 5/5 vundet, 500 gæster 2.7 ms/tick. Visuel bekræftelse af brugeren → review.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
