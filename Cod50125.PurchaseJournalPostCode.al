tableextension 50129 GLSetupExt extends "General Ledger Setup"
{
    fields
    {
        field(50100; "Close AP"; Boolean)
        {
            Caption = 'Closed for AP';
            DataClassification = CustomerContent;
        }
    }

}
pageextension 50130 GLSetupExt extends "General ledger Setup"
{
    layout
    {
        addafter("Allow Posting To")
        {
            field("Close AP"; "Close AP")
            {
                Caption = 'Closed for AP';
                ToolTip = 'This is a custom field which is used by Bill.com Syncrhonizer application. If this flag is set to ON then the posting period is assumed closed for AP usage and hence no posting of Purchase or Payment Journals is made.';
                ApplicationArea = All;
            }
        }
    }
}

codeunit 50125 PurchaseJournalPostCode
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrentJnlBatchName: Code[10];
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        Genjournalbatch: Record "Gen. Journal Batch";
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
            GenJnlLine.SetFilter("Journal Template Name", 'PURCHASES');
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
                //               DeleteCurrentBatch(Batchname);
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
            Genjournalbatch."Journal Template Name" := 'PURCHASES';
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
