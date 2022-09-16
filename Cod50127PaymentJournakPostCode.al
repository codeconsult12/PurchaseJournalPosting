codeunit 50127 PaymentJournalPostCode
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrentJnlBatchName: Code[10];
        Genjournalbatch: Record "Gen. Journal Batch";
        genjnlbatchname: text[100];
        Isbtchentriesavailable: Boolean;
        JobQueuesUsed: Boolean;
        JobQueueVisible: Boolean;
        GenJnlLine: Record "Gen. Journal Line";



    procedure RunCodeUnit(var Batchname: Text[100]) Returnvalue: Text[100]
    var
        result: Text[50];
        GlSetup: record "General Ledger Setup";
        CheckAP: Boolean;
    begin
        if (Batchname <> '')
        then begin
            GenJnlLine.SetFilter("Journal Batch Name", Batchname);
            GenJnlLine.SetFilter("Journal Template Name", 'PAYMENTS');
            CurrentJnlBatchName := Batchname;

            if GlSetup.FindFirst() then begin
                if GenJnlLine.FindSet()
                then
                    repeat
                        if (GenJnlLine."Posting Date" < GlSetup."Allow Posting From")
                        then begin
                            GenJnlLine."Posting Date" := GlSetup."Allow Posting From";
                            GenJnlLine.Modify();
                            CheckAP := false;
                        end;
                        if GlSetup."Close AP"
                        then begin
                            CheckAP := true;
                        end;

                        Isbtchentriesavailable := true;
                    Until GenJnlLine.Next() = 0;
            end;
            if CheckAP <> true then begin
                CODEUNIT.Run(CODEUNIT::"GenJournalPostNew", GenJnlLine);
                CurrentJnlBatchName := GenJnlLine.GetRangeMax("Journal Batch Name");
                SetJobQueueVisibility();
                result := 'Success';
                ReturnValue := result;
            end else begin
                //                DeleteCurrentBatch(Batchname);
                result := 'AP is Closed';
                ReturnValue := result;
            end;
        end
        else begin
            result := 'UnSuccess';
            ReturnValue := result;
        end;

    end;

    procedure DeleteCurrentBatch(var Batchname: Text[100])
    begin
        if Batchname <> ''
        then begin
            Genjournalbatch."Journal Template Name" := 'PAYMENTS';
            Genjournalbatch.Name := Batchname;
            Genjournalbatch.Delete();
        end;
    end;

    local procedure SetJobQueueVisibility()
    begin
        JobQueueVisible := GenJnlLine."Job Queue Status" = GenJnlLine."Job Queue Status"::"Scheduled for Posting";
        JobQueuesUsed := GeneralLedgerSetup.JobQueueActive();
    end;
}
