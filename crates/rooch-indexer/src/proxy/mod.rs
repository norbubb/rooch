// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

use crate::actor::indexer::IndexerActor;
use crate::actor::messages::{
    IndexerEventsMessage, IndexerStatesMessage, IndexerTransactionMessage,
    QueryIndexerEventsMessage, QueryIndexerGlobalStatesMessage, QueryIndexerTableStatesMessage,
    QueryIndexerTransactionsMessage, SyncIndexerStatesMessage,
};
use anyhow::Result;
use coerce::actor::ActorRef;
use moveos_types::moveos_std::event::Event;
use moveos_types::state::StateChangeSet;
use moveos_types::transaction::{TransactionExecutionInfo, VerifiedMoveOSTransaction};
use rooch_types::indexer::event_filter::{EventFilter, IndexerEvent, IndexerEventID};
use rooch_types::indexer::state::{
    GlobalStateFilter, IndexerGlobalState, IndexerStateID, IndexerTableChangeSet,
    IndexerTableState, StateSyncFilter, TableStateFilter,
};
use rooch_types::indexer::transaction_filter::TransactionFilter;
use rooch_types::transaction::{TransactionSequenceInfo, TransactionWithInfo, TypedTransaction};

#[derive(Clone)]
pub struct IndexerProxy {
    pub actor: ActorRef<IndexerActor>,
}

impl IndexerProxy {
    pub fn new(actor: ActorRef<IndexerActor>) -> Self {
        Self { actor }
    }

    pub async fn indexer_states(
        &self,
        tx_order: u64,
        state_change_set: StateChangeSet,
    ) -> Result<()> {
        self.actor
            .send(IndexerStatesMessage {
                tx_order,
                state_change_set,
            })
            .await?
    }

    pub async fn indexer_transaction(
        &self,
        transaction: TypedTransaction,
        sequence_info: TransactionSequenceInfo,
        execution_info: TransactionExecutionInfo,
        moveos_tx: VerifiedMoveOSTransaction,
    ) -> Result<()> {
        self.actor
            .send(IndexerTransactionMessage {
                transaction,
                sequence_info,
                execution_info,
                moveos_tx,
            })
            .await?
    }

    pub async fn indexer_events(
        &self,
        events: Vec<Event>,
        transaction: TypedTransaction,
        sequence_info: TransactionSequenceInfo,
        moveos_tx: VerifiedMoveOSTransaction,
    ) -> Result<()> {
        self.actor
            .send(IndexerEventsMessage {
                events,
                transaction,
                sequence_info,
                moveos_tx,
            })
            .await?
    }

    pub async fn query_transactions(
        &self,
        filter: TransactionFilter,
        // exclusive cursor if `Some`, otherwise start from the beginning
        cursor: Option<u64>,
        limit: usize,
        descending_order: bool,
    ) -> Result<Vec<TransactionWithInfo>> {
        self.actor
            .send(QueryIndexerTransactionsMessage {
                filter,
                cursor,
                limit,
                descending_order,
            })
            .await?
    }

    pub async fn query_events(
        &self,
        filter: EventFilter,
        // exclusive cursor if `Some`, otherwise start from the beginning
        cursor: Option<IndexerEventID>,
        limit: usize,
        descending_order: bool,
    ) -> Result<Vec<IndexerEvent>> {
        self.actor
            .send(QueryIndexerEventsMessage {
                filter,
                cursor,
                limit,
                descending_order,
            })
            .await?
    }

    pub async fn query_global_states(
        &self,
        filter: GlobalStateFilter,
        // exclusive cursor if `Some`, otherwise start from the beginning
        cursor: Option<IndexerStateID>,
        limit: usize,
        descending_order: bool,
    ) -> Result<Vec<IndexerGlobalState>> {
        self.actor
            .send(QueryIndexerGlobalStatesMessage {
                filter,
                cursor,
                limit,
                descending_order,
            })
            .await?
    }

    pub async fn query_table_states(
        &self,
        filter: TableStateFilter,
        // exclusive cursor if `Some`, otherwise start from the beginning
        cursor: Option<IndexerStateID>,
        limit: usize,
        descending_order: bool,
    ) -> Result<Vec<IndexerTableState>> {
        self.actor
            .send(QueryIndexerTableStatesMessage {
                filter,
                cursor,
                limit,
                descending_order,
            })
            .await?
    }

    pub async fn sync_states(
        &self,
        filter: Option<StateSyncFilter>,
        // exclusive cursor if `Some`, otherwise start from the beginning
        cursor: Option<IndexerStateID>,
        limit: usize,
        descending_order: bool,
    ) -> Result<Vec<IndexerTableChangeSet>> {
        self.actor
            .send(SyncIndexerStatesMessage {
                filter,
                cursor,
                limit,
                descending_order,
            })
            .await?
    }
}
