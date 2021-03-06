#include "oclint/AbstractASTVisitorRule.h"
#include "oclint/RuleSet.h"
#include "oclint/util/StdUtil.h"

class ThrowExceptionFromFinallyBlockRule :
    public AbstractASTVisitorRule<ThrowExceptionFromFinallyBlockRule>
{
    class ExtractObjCAtThrowStmts : public RecursiveASTVisitor<ExtractObjCAtThrowStmts>
    {
    private:
        vector<ObjCAtThrowStmt*> *_throws;

    public:
        void extract(ObjCAtFinallyStmt *finallyStmt, vector<ObjCAtThrowStmt*> *throws)
        {
            _throws = throws;
            (void) /* explicitly ignore the return of this function */ TraverseStmt(finallyStmt);
        }

        bool VisitObjCAtThrowStmt(ObjCAtThrowStmt *throwStmt)
        {
            _throws->push_back(throwStmt);
            return true;
        }
    };

    class ExtractNSExceptionRaiser : public RecursiveASTVisitor<ExtractNSExceptionRaiser>
    {
    private:
        vector<ObjCMessageExpr*> *_raisers;

    public:
        void extract(ObjCAtFinallyStmt *finallyStmt, vector<ObjCMessageExpr*> *raisers)
        {
            _raisers = raisers;
            (void) /* explicitly ignore the return of this function */ TraverseStmt(finallyStmt);
        }

        bool VisitObjCMessageExpr(ObjCMessageExpr *objCMsgExpr)
        {
            string selectorString = objCMsgExpr->getSelector().getAsString();
            vector<string> selectorStrings;
            selectorStrings.push_back("raise");
            selectorStrings.push_back("raise:format:");
            selectorStrings.push_back("raise:format:arguments:");
            bool isRaiseMethod = vectorContains<string>(selectorString, selectorStrings);

            ObjCInterfaceDecl *objCInterfaceDecl = objCMsgExpr->getReceiverInterface();
            bool isNSExceptionClass = objCInterfaceDecl &&
                objCInterfaceDecl->getNameAsString() == "NSException";

            if (isRaiseMethod && isNSExceptionClass)
            {
                _raisers->push_back(objCMsgExpr);
            }

            return true;
        }
    };

private:
    static RuleSet rules;

public:
    virtual const string name() const
    {
        return "throw exception from finally block";
    }

    virtual int priority() const
    {
        return 2;
    }

    bool VisitObjCAtFinallyStmt(ObjCAtFinallyStmt *finallyStmt)
    {
        vector<ObjCAtThrowStmt*> *throws = new vector<ObjCAtThrowStmt*>();
        ExtractObjCAtThrowStmts extractThrowStmts;
        extractThrowStmts.extract(finallyStmt, throws);
        for (int index = 0; index < throws->size(); index++)
        {
            ObjCAtThrowStmt *throwStmt = throws->at(index);
            addViolation(throwStmt, this);
        }

        vector<ObjCMessageExpr*> *exceptionRaisers = new vector<ObjCMessageExpr*>();
        ExtractNSExceptionRaiser extractExceptions;
        extractExceptions.extract(finallyStmt, exceptionRaisers);
        for (int index = 0; index < exceptionRaisers->size(); index++)
        {
            ObjCMessageExpr *raiseExpr = exceptionRaisers->at(index);
            addViolation(raiseExpr, this);
        }

        return true;
    }
};

RuleSet ThrowExceptionFromFinallyBlockRule::rules(new ThrowExceptionFromFinallyBlockRule());
