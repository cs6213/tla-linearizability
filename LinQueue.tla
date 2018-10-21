----------------------------- MODULE LinQueue -------------------------------
EXTENDS Naturals, Sequences, TLC

opInvocations == {"E", "D"}
opResponse == "Ok"

Values == {"x", "y", "z"} 
Processes == {"A", "B", "C"}

\* Process subhistory
H|P == SelectSeq(H, LAMBDA e : e.proc = P)

PossibleResponses(e) ==
    CASE e.op = "E" -> {[op|->"Ok", proc|->e.proc]}
      [] e.op = "D" -> [op:{"Ok"}, proc:{e.proc}, val:Values]

IsInvocation(e) == e.op \in opInvocations

Matches(H, i, j) ==
    /\ H[i].proc = H[j].proc
    /\ H[i].op \in opInvocations
    /\ H[j].op = opResponse
    /\ "val" \in DOMAIN H[j] <=> H[i].op = "D" \* Only dequeues have values in the response
    /\ ~\E k \in (i+1)..(j-1) : H[k].proc = H[i].proc


RECURSIVE LegalQueue(_, _)

\* Check if a history h is legal given an initial queue state q
LegalQueue(h, q) == \/ h = << >>
                    \/ LET first == Head(h)
                           rest == Tail(h)
                       IN \/ /\ first.op = "E" 
                             /\ LegalQueue(rest, Append(q, first.val))
                          \/ /\ first.op = "D"
                             /\ Len(q)>0
                             /\ first.val = Head(q)
                             /\ LegalQueue(rest, Tail(q))

IsLegalQueueHistory(h) == LegalQueue(h, << >>)

IsLegalSequentialHistory(H) == 
    LET RECURSIVE Helper(_, _)
        Helper(h, s) == 
            CASE h = << >> -> IsLegalQueueHistory(s)
              [] Len(h) = 1 -> FALSE
              [] Matches(h,1,2) -> LET hr == Tail(Tail(h))
                                       inv == h[1]
                                       res == h[2]
                                       e == [op|->inv.op, val|-> IF inv.op = "E" THEN inv.val ELSE res.val]
                                   IN Helper(hr, Append(s, e))
              [] OTHER -> FALSE
    IN Helper(H, <<>>)

L == INSTANCE Linearizability

IsLin(H) == L!IsLinearizableHistory(H)

=============================================================================
