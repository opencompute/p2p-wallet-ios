import Foundation
import Combine

/// A machine that consists of a set of states, actions, and a dispatcher that controls transition rules and define how the system transitions from one state to another based on the inputs it receives.
public actor StateMachine<
    State: KeyAppStateMachine.State,
    Action: KeyAppStateMachine.Action,
    Dispatcher: KeyAppStateMachine.Dispatcher<State, Action>
> {

    // MARK: - Dependencies

    /// Dispatcher that controls dispatching actions
    private let dispatcher: Dispatcher

    // MARK: - Private properties

    /// Subject that holds a stream of current state, start with an initial state
    private let stateSubject = CurrentValueSubject<State, Never>(.initial)

    /// Current active action
    private var currentAction: Action?

    /// Current working task
    private var currentTask: Task<Void, Never>?

    // MARK: - Public properties
    
    /// Publisher that emit a stream of current state to listener
    public nonisolated var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    /// The current state of the machine
    public nonisolated var currentState: State {
        stateSubject.value
    }

    // MARK: - Initialization
    
    /// `StateMachine`'s initialization
    /// - Parameter dispatcher: Dispatcher that controls dispatching actions
    init(dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
    }

    // MARK: - Public methods
    
    /// Accept a new action
    /// - Parameter action: new action
    public nonisolated func accept(action: Action) async {
        
        // Check if action should be dispatched
        guard await !dispatcher.shouldBeginDispatching(
            currentAction: currentAction,
            newAction: action,
            currentState: currentState
        ) else {
            return
        }
        
        // Check if new action should cancel current action
        if await dispatcher.shouldCancelCurrentAction(
            currentAction: currentAction,
            newAction: action,
            currentState: currentState
        ) {
            // Cancel current action
            await currentTask?.cancel()
        }
        
        // If current task is not cancelled
        else if let currentTask = await currentTask, currentTask.isCancelled == false {
            // Wait for current action to be completed
            await currentTask.value
        }
        
        // Dispatch action
        await saveCurrentAction(action)
        await saveCurrentTask(.init { [unowned self] in
            await performAction(action: action)
        })
    }

    // MARK: - Private methods
    
    /// Perform an action by delegating works to dispatcher
    private func performAction(action: Action) async {
        // loading state whene action is about to be dispatched
        stateSubject.send(
            await dispatcher.actionWillBeginDispatching(
                action: action,
                currentState: currentState
            )
        )
        
        // check cancellation
        guard !Task.isCancelled else { return }
        
        // dispatch action
        stateSubject.send(
            await dispatcher.dispatch(
                action: action,
                currentState: currentState
            )
        )
        
        // check cancellation
        guard !Task.isCancelled else { return }
        
        // additional state when action is dispatched
        stateSubject.send(
            await dispatcher.actionDidEndDispatching(
                action: action,
                currentState: currentState
            )
        )
        
        // remove current task / action
        saveCurrentAction(nil)
        saveCurrentTask(nil)
    }
    
    /// Save current action
    private func saveCurrentAction(_ action: Action?) {
        currentAction = action
    }

    /// Save current task
    private func saveCurrentTask(_ task: Task<Void, Never>?) {
        currentTask = task
    }
}
